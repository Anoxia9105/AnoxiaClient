import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/core/device_identity.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/constants/api.dart';
import '../../codec/frame_codec.dart';
import '../../codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../../network/token_manager.dart';
import '../../protocol/i_packet.dart';
import '../../protocol/packet_frame.dart';
import '../../protocol/packet_registry.dart';
import 'ws_state.dart';

part 'ws_controller.g.dart';

/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。
@Riverpod(keepAlive: true)
class WsController extends _$WsController {
  static const int _maxAutoRetryAttempts = 2;
  static const Duration _defaultAckTimeout = Duration(seconds: 15);
  static const int _maxPendingOutbounds = 500;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _reconnectEnabled = true;
  int? _lastAckErrorCode;
  String? _lastAckErrorMessage;
  DateTime? _lastAckErrorAt;
  bool _lastNetworkAvailable = true;

  final Map<String, _PendingOutbound> _pendingOutbounds = {};

  late final StreamController<PacketFrame<IPacket>> _messageController;

  @override
  WsState build() {
    debugLog('🌐 WsController 构建中...');

    _messageController = StreamController<PacketFrame<IPacket>>.broadcast();

    // 监听认证状态变化：登录时连接，登出时断开
    ref.listen(authControllerProvider, (previous, next) {
      debugLog(
        '[WsController] auth 状态变更: prev=${previous?.value != null}, next=${next.value != null}, nextLoading=${next.isLoading}, nextHasError=${next.hasError}',
      );
      next.when(
        data: (user) {
          if (user != null) {
            debugLog('[WsController] 检测到用户登录，准备连接...');
            _reconnectEnabled = true;
            _initConnection();
          } else {
            debugLog('[WsController] 检测到用户退出，断开连接...');
            _reconnectEnabled = false;
            unawaited(_disposeAll(closeStream: false, manual: true));
          }
        },
        error: (err, _) {
          _reconnectEnabled = false;
          unawaited(_disposeAll(closeStream: false, manual: true));
        },
        loading: () => {},
      );
    });

    ref.listen(networkStatusProvider, (previous, next) {
      final statuses = next.value;
      if (statuses == null || statuses.isEmpty) return;

      final bool available = !statuses.contains(ConnectivityResult.none);
      final bool recovered = !_lastNetworkAvailable && available;
      _lastNetworkAvailable = available;

      if (recovered) {
        debugLog('[WsController] 网络已恢复，主动触发连接恢复');
        _reconnectAttempts = 0;
        _initConnection();
      }
    });

    // 初始启动检查：如果 build 时已经有用户了，直接触发连接
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser != null) {
      Future.microtask(() => _initConnection());
    }

    ref.onDispose(() {
      _reconnectEnabled = false;
      unawaited(_disposeAll(closeStream: true, manual: true));
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
      debugLog('[WsController] 初始化失败：未找到 Token');
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
      final deviceId = await DeviceIdentity.instance.getPlatformQualifiedId();
      final url =
          '${API.wsBaseUrl}${Uri.encodeQueryComponent(token)}'
          '&deviceId=${Uri.encodeQueryComponent(deviceId)}';
      debugLog('[WsController] 正在尝试建立 WebSocket 连接');

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
      debugLog('✅ WebSocket 连接成功');

      _startHeartbeat();
    } catch (e, st) {
      debugLog('❌ WebSocket 连接失败', e, st);
      _handleError(e);
    }
  }

  /// 发送二进制消息（V5 协议帧）
  void sendMessage(
    dynamic msg, {
    String? clientMsgId,
    Duration ackTimeout = _defaultAckTimeout,
  }) {
    // 统一转换为 Uint8List
    final Uint8List? bytes = _toBytes(msg);
    if (bytes == null) return;

    if (state.status != WsStatus.connected) {
      debugLog('尝试在未连接状态发送消息，交给本地持久化队列处理');
      return;
    }

    try {
      _cachePendingOutbound(
        bytes,
        clientMsgId: clientMsgId,
        ackTimeout: ackTimeout,
      );
      _channel?.sink.add(bytes);
    } catch (e) {
      if (clientMsgId != null) {
        _removePendingOutbound(clientMsgId);
        unawaited(
          ref
              .read(chatMessagesProvider.notifier)
              .markFailedByClientMsgId(clientMsgId),
        );
      }
      debugLog('发送消息失败', e);
    }
  }

  static Uint8List? _toBytes(dynamic msg) {
    if (msg is Uint8List) return msg;
    if (msg is List<int>) return Uint8List.fromList(msg);
    // 旧调用兼容（'ping' 等文本）——忽略，心跳已改为二进制帧
    return null;
  }

  void _cachePendingOutbound(
    Uint8List bytes, {
    String? clientMsgId,
    required Duration ackTimeout,
  }) {
    final seq = clientMsgId ?? _extractSeqFromBytes(bytes);
    if (seq == null || seq.isEmpty) return;
    if (_pendingOutbounds.length >= _maxPendingOutbounds) {
      final oldestKey = _pendingOutbounds.keys.first;
      _removePendingOutbound(oldestKey);
      unawaited(
        ref
            .read(chatMessagesProvider.notifier)
            .markFailedByClientMsgId(oldestKey),
      );
    }
    _removePendingOutbound(seq);
    final pending = _PendingOutbound(bytes: bytes);
    pending.timeoutTimer = Timer(ackTimeout, () {
      if (!_pendingOutbounds.containsKey(seq)) return;
      _removePendingOutbound(seq);
      unawaited(
        ref.read(chatMessagesProvider.notifier).markFailedByClientMsgId(seq),
      );
      debugLog('[WsController] ACK timeout: clientMsgId=$seq');
    });
    _pendingOutbounds[seq] = pending;
  }

  void _removePendingOutbound(String clientMsgId) {
    _pendingOutbounds.remove(clientMsgId)?.timeoutTimer?.cancel();
  }

  /// 从二进制帧中提取 clientMsgId（用作 ACK 等待队列 key）
  String? _extractSeqFromBytes(Uint8List bytes) {
    try {
      final frame = FrameCodec.parse(bytes);
      if (!frame.isProtobuf) return null;
      final decoded = ImPacketV5.decodeEnvelope(frame.body);
      if (decoded == null || !decoded.isData) return null;
      final payload = decoded.payload!;
      // 只有 RoomMessage 类型才有 clientMsgId
      if (decoded.codecId == ImPacketV5.codecRoomMessage) {
        final msg = ImPacketV5.decodeRoomMessage(payload);
        return msg?.clientMsgId ?? msg?.messageId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 处理接收到的消息（V5 二进制帧）
  void _handleIncomingMessage(dynamic message) {
    // 只处理二进制帧
    if (message is! List<int>) {
      debugLog('[WsController] 收到非二进制消息，忽略');
      return;
    }
    final bytes = message is Uint8List ? message : Uint8List.fromList(message);
    debugLog('[SERVER FRAME]: ${bytes.length} bytes');

    try {
      final decoded = ImPacketV5.decodeFrame(bytes);
      if (decoded == null) return;

      if (decoded.isPing) {
        // 服务端 Ping → 回 Pong
        _channel?.sink.add(FrameCodec.buildPong());
        return;
      }
      if (decoded.isPong) return; // 忽略 Pong

      if (!decoded.isData) return;
      final payload = decoded.payload!;
      final topic = decoded.topic!;
      final effectiveTopic = PacketRegistry.topicForCodecId(
        decoded.codecId,
        topic,
      );

      // ACK 帧：特殊处理
      if (decoded.isAck) {
        final ack = ImPacketV5.decodeAck(payload);
        if (ack != null) {
          // 打印 ACK 详情
          debugLog('[SERVER ACK] topic=$topic code=${ack.code}');
          try {
            _handleAckV5(ack);
          } catch (ackError, ackStack) {
            // ACK 处理是业务副作用（刷新 Riverpod 状态等），失败不应中断后续帧的解析。
            // 例如 Web 热重载后 ref 可能持有旧模块对象，触发 NoSuchMethodError。
            debugLog('WS ACK 处理异常', ackError, ackStack);
          }
        }
        return;
      }

      final packetData = PacketRegistry.parse(topic, payload, decoded.codecId);
      debugLog(
        '[SERVER DATA] dispatch -> Topic: $topic, CodecId: ${decoded.codecId}, EffectiveTopic: $effectiveTopic, PayloadSize: ${payload.length}',
      );
      if (packetData != null) {
        final frame = PacketFrame(topic: effectiveTopic, data: packetData);
        try {
          if (!_messageController.isClosed) {
            _messageController.add(frame);
          }
        } catch (dispatchError, dispatchStack) {
          // 派发到业务订阅者时失败（如监听者持有热重载前的旧类型）不应中断消息解析。
          debugLog('WS 消息派发异常', dispatchError, dispatchStack);
        }
      } else {
        debugLog('[SERVER DATA] 解析失败（未知的 Topic 或解析器缺失）-> Topic: $topic');
      }
    } catch (e, st) {
      debugLog('WS 消息解析异常', e, st);
    }
  }

  /// 处理 V5 ACK
  void _handleAckV5(AckV5 ack) {
    final seq = ack.clientMessageId;
    if (ack.isSuccess) {
      if (seq != null && seq.isNotEmpty) {
        _removePendingOutbound(seq);
        ref
            .read(chatMessagesProvider.notifier)
            .markAcked(
              clientMsgId: seq,
              roomId: ack.meta?.roomId,
              messageId: ack.meta?.messageId,
              seq: ack.meta?.seq,
              timestamp: ack.meta?.timestamp,
            );
      }
      return;
    }

    // 业务错误
    if (seq != null && seq.isNotEmpty) {
      if (ack.retryable) {
        _retryPendingOutbound(seq);
      } else {
        _removePendingOutbound(seq);
        ref.read(chatMessagesProvider.notifier).markFailedByClientMsgId(seq);
      }
    }

    final code = ack.code;
    final rawMessage = ack.message ?? '';
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
      ref.read(toastServiceProvider).showToast(
        _resolveAckErrorMessage(code, rawMessage),
        type: ToastType.error,
      );
    }
    debugLog('[WsController] ACK业务失败: code=$code, message=$rawMessage');
  }

  void _retryPendingOutbound(String seq) {
    final pending = _pendingOutbounds[seq];
    if (pending == null) return;
    if (pending.retryScheduled) return;

    if (pending.attempts >= _maxAutoRetryAttempts) {
      _removePendingOutbound(seq);
      unawaited(
        ref.read(chatMessagesProvider.notifier).markFailedByClientMsgId(seq),
      );
      debugLog('[WsController] 自动重试超过上限，放弃: seq=$seq');
      return;
    }

    pending.attempts += 1;
    pending.retryScheduled = true;
    final delay = Duration(milliseconds: 300 * (1 << (pending.attempts - 1)));
    Future.delayed(delay, () {
      pending.retryScheduled = false;
      if (!_pendingOutbounds.containsKey(seq)) return;
      if (state.status != WsStatus.connected) return;

      if (pending.attempts > _maxAutoRetryAttempts) {
        _removePendingOutbound(seq);
        debugLog('[WsController] 自动重试超过上限(延迟触发)，放弃: seq=$seq');
        return;
      }

      try {
        _channel?.sink.add(pending.bytes);
        debugLog(
          '[WsController] 已触发自动重试: seq=$seq, attempt=${pending.attempts}',
        );
      } catch (e) {
        debugLog('[WsController] 自动重试发送失败: seq=$seq', e);
      }
    });
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
        _channel?.sink.add(FrameCodec.buildPing());
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
    debugLog('WebSocket 连接关闭: closeCode=$closeCode, closeReason=$closeReason');
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

    final delaySeconds = _calculateReconnectDelay();
    debugLog('将在 $delaySeconds 秒后进行第 ${_reconnectAttempts + 1} 次重连...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectAttempts++;
      _initConnection();
    });
  }

  int _calculateReconnectDelay() {
    final baseDelay = (1 << _reconnectAttempts).clamp(2, 30);
    final jitterMs = math.Random().nextInt(baseDelay * 1000);
    return math.max(1, (jitterMs / 1000).round());
  }

  /// 登出时主动断开连接
  Future<void> disconnectForLogout() async {
    _reconnectEnabled = false;
    await _disposeAll(closeStream: false, manual: true);
  }

  /// 清理所有资源
  ///
  /// [closeStream] 是否关闭消息流（登出时不断流，断开网络连接即可）
  /// [manual] 是否为手动触发
  Future<void> _disposeAll({
    bool closeStream = false,
    bool manual = false,
  }) async {
    debugLog(
      '[WsController] 执行断开: closeStream=$closeStream, manual=$manual, state=${state.status}',
    );
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    final channel = _channel;
    _channel = null;
    for (final pending in _pendingOutbounds.values) {
      pending.timeoutTimer?.cancel();
    }
    _pendingOutbounds.clear();
    _reconnectAttempts = 0;
    if (closeStream) {
      _messageController.close();
    }
    state = WsState(status: WsStatus.disconnected);
    try {
      await channel?.sink.close();
    } catch (e) {
      debugLog('[WsController] 关闭 WebSocket 时发生异常: $e');
    }
  }
}

class _PendingOutbound {
  _PendingOutbound({required this.bytes});

  final Uint8List bytes; // 原始二进制，用于连接内 ACK 重试发送
  int attempts = 0;
  bool retryScheduled = false;
  Timer? timeoutTimer;
}

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息
@riverpod
Stream<PacketFrame<IPacket>> wsMessageStream(Ref ref) {
  final wsController = ref.read(wsControllerProvider.notifier);
  return wsController.messageStream;
}
