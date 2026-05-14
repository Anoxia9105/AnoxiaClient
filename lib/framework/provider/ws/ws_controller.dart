import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/constants/API.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../../protocol/IPacket.dart';
import '../../protocol/PacketFrame.dart';
import '../../protocol/PacketType.dart';
import '../../protocol/register/PacketRegistry.dart';
import 'ws_state.dart';

part 'ws_controller.g.dart';

/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。
@Riverpod(keepAlive: true)
class WsController extends _$WsController {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _reconnectEnabled = true;
  int? _lastAckErrorCode;
  String? _lastAckErrorMessage;
  DateTime? _lastAckErrorAt;

  late final StreamController<PacketFrame<IPacket>> _messageController;

  @override
  WsState build() {
    log.info("🌐 WsController 构建中...");

    _messageController = StreamController<PacketFrame<IPacket>>.broadcast();

    // 监听认证状态变化：登录时连接，登出时断开
    ref.listen(authControllerProvider, (previous, next) {
      log.info(
        "[WsController] auth 状态变更: prev=${previous?.value != null}, next=${next.value != null}, nextLoading=${next.isLoading}, nextHasError=${next.hasError}",
      );
      next.when(
        data: (user) {
          if (user != null) {
            log.info("[WsController] 检测到用户登录，准备连接...");
            _reconnectEnabled = true;
            _initConnection();
          } else {
            log.info("[WsController] 检测到用户退出，断开连接...");
            _reconnectEnabled = false;
            _disposeAll(closeStream: false, manual: true);
          }
        },
        error: (err, _) {
          _reconnectEnabled = false;
          _disposeAll(closeStream: false, manual: true);
        },
        loading: () => {},
      );
    });

    // 初始启动检查：如果 build 时已经有用户了，直接触发连接
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser != null) {
      Future.microtask(() => _initConnection());
    }

    ref.onDispose(() {
      _reconnectEnabled = false;
      _disposeAll(closeStream: true, manual: true);
    });

    return WsState(status: WsStatus.disconnected);
  }

  /// 消息流，供外部监听 WebSocket 消息
  Stream<PacketFrame<IPacket>> get messageStream => _messageController.stream;

  /// 初始化连接
  Future<void> _initConnection() async {
    // 保护：如果已经在连接或已连接，跳过
    if (state.status == WsStatus.connecting ||
        state.status == WsStatus.connected) {
      return;
    }

    final token = await TokenManager.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await connect(token);
    } else {
      log.warning("[WsController] 初始化失败：未找到 Token");
    }
  }

  /// 建立 WebSocket 连接
  ///
  /// [token] 认证令牌，用于建立连接
  Future<void> connect(String token) async {
    if (state.status == WsStatus.connected) {
      return;
    }
    if (!_reconnectEnabled) {
      return;
    }

    state = WsState(status: WsStatus.connecting);

    try {
      final url = "${API.wsBaseUrl}$token";
      log.info("[WsController] 正在尝试建立 WebSocket 连接: $url");

      if (kIsWeb) {
        _channel = WebSocketChannel.connect(Uri.parse(url));
      } else {
        // 桌面端关闭压缩扩展协商，避免部分代理链路下触发 1002(PROTOCOL_ERROR)
        final socket = await io.WebSocket.connect(
          url,
          compression: io.CompressionOptions.compressionOff,
        );
        _channel = IOWebSocketChannel(socket);
      }
      await _channel!.ready;

      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message),
        onError: (err) => _handleError(err),
        onDone: () => _handleDone(),
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      state = WsState(status: WsStatus.connected);
      log.info("✅ WebSocket 连接成功");

      _startHeartbeat();
    } catch (e, st) {
      log.error("❌ WebSocket 连接失败", e, st);
      _handleError(e);
    }
  }

  /// 发送消息
  void sendMessage(dynamic msg) {
    if (state.status != WsStatus.connected) {
      log.warning("尝试在未连接状态发送消息");
      return;
    }

    try {
      final data = msg is Map ? jsonEncode(msg) : msg;
      _channel?.sink.add(data);
    } catch (e) {
      log.error("发送消息失败", e);
    }
  }

  /// 处理接收到的消息
  void _handleIncomingMessage(dynamic message) {
    log.info("【WS收到消息】,${message.toString()}");
    if (message == 'pong') return;

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(message as String);

      // 兼容旧格式 ACK：顶层 {code, message, retryable}
      if (_handleLegacyAckError(jsonMap)) {
        return;
      }

      final topic = PacketType.from(jsonMap['topic']);
      final rawData = jsonMap['data'] as Map<String, dynamic>?;

      if (rawData == null) return;

      // 新格式 ACK：PacketFrame(EVENT, data={code,message,retryable,...})
      if (_handleAckError(rawData)) {
        return;
      }

      final packetData = PacketRegistry.parse(topic, rawData);
      if (packetData != null) {
        final frame = PacketFrame(topic: topic, data: packetData);
        if (!_messageController.isClosed) {
          _messageController.add(frame);
        }
      }
    } catch (e) {
      log.error("WS 消息解析异常", e);
    }
  }

  /// 处理旧格式 ACK 错误
  bool _handleLegacyAckError(Map<String, dynamic> jsonMap) {
    if (jsonMap.containsKey('topic')) return false;
    return _handleAckError(jsonMap);
  }

  /// 处理 ACK 错误
  ///
  /// 解析服务器返回的业务错误码，并显示 Toast 提示
  /// 2 秒内的重复错误不会重复提示（防抖）
  bool _handleAckError(Map<String, dynamic> jsonMap) {
    if (!jsonMap.containsKey('code')) return false;

    final int? code = int.tryParse(jsonMap['code']?.toString() ?? '');
    final String rawMessage = (jsonMap['message']?.toString() ?? '').trim();

    // code=0 代表成功 ACK，静默即可
    if (code == null || code == 0) return true;

    final now = DateTime.now();
    final bool duplicated =
        _lastAckErrorCode == code &&
        _lastAckErrorMessage == rawMessage &&
        _lastAckErrorAt != null &&
        now.difference(_lastAckErrorAt!) < const Duration(seconds: 2);

    if (!duplicated) {
      _lastAckErrorCode = code;
      _lastAckErrorMessage = rawMessage;
      _lastAckErrorAt = now;
      Toast.showToast(
        _resolveAckErrorMessage(code, rawMessage),
        type: ToastType.error,
      );
    }

    log.warning('[WsController] ACK业务失败: code=$code, message=$rawMessage');
    return true;
  }

  /// 解析错误码对应的用户提示
  String _resolveAckErrorMessage(int code, String serverMessage) {
    switch (code) {
      case 2001:
        return 'chat_send_failed_not_friend'.tr();
      case 2002:
        return 'chat_send_failed_blocked'.tr();
      case 2003:
        return 'chat_send_failed_deleted'.tr();
      default:
        if (serverMessage.isNotEmpty) {
          return 'chat_send_failed_with_reason'.tr(args: [serverMessage]);
        }
        return 'chat_send_failed_generic'.tr();
    }
  }

  /// 启动心跳定时器
  ///
  /// 每 30 秒发送一次 ping，保持连接活跃
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.status == WsStatus.connected) {
        sendMessage('ping');
      } else {
        timer.cancel();
      }
    });
  }

  /// 处理连接错误
  void _handleError(dynamic err) {
    state = WsState(status: WsStatus.error, error: err.toString());
    _retryConnection();
  }

  /// 处理连接关闭
  void _handleDone() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    log.info("WebSocket 连接关闭: closeCode=$closeCode, closeReason=$closeReason");
    state = WsState(status: WsStatus.disconnected);
    _retryConnection();
  }

  /// 指数退避重连
  ///
  /// 重连间隔：2s, 4s, 8s... 最大 30s
  void _retryConnection() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (!_reconnectEnabled) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    int delaySeconds = (1 << _reconnectAttempts).clamp(2, 30);
    log.warning("将在 $delaySeconds 秒后进行第 ${_reconnectAttempts + 1} 次重连...");

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectAttempts++;
      _initConnection();
    });
  }

  /// 登出时主动断开连接
  Future<void> disconnectForLogout() async {
    _reconnectEnabled = false;
    _disposeAll(closeStream: false, manual: true);
  }

  /// 清理所有资源
  ///
  /// [closeStream] 是否关闭消息流（登出时不断流，断开网络连接即可）
  /// [manual] 是否为手动触发
  void _disposeAll({bool closeStream = false, bool manual = false}) {
    log.info(
      "[WsController] 执行断开: closeStream=$closeStream, manual=$manual, state=${state.status}",
    );
    log.info("[WsController] 断开调用栈: ${StackTrace.current}");
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempts = 0;
    if (closeStream) {
      _messageController.close();
    }
    state = WsState(status: WsStatus.disconnected);
  }
}

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息
@riverpod
Stream<PacketFrame<IPacket>> wsMessageStream(Ref ref) {
  final wsController = ref.watch(wsControllerProvider.notifier);
  return wsController.messageStream;
}
