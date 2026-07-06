import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/constants/API.dart';
import '../../codec/FrameCodec.dart';
import '../../codec/v5/ImPacketV5.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../../protocol/IPacket.dart';
import '../../protocol/PacketFrame.dart';
import '../../protocol/register/PacketRegistry.dart';
import 'ws_state.dart';

part 'ws_controller.g.dart';

/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。
@Riverpod(keepAlive: true)
class WsController extends _$WsController {
  static const int _maxAutoRetryAttempts = 2;
  static const int _maxOfflineQueueSize = 200;
  static const int _offlineFlushBatchSize = 20;
  static const Duration _offlineFlushBatchInterval = Duration(milliseconds: 50);

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _offlineFlushTimer;
  int _reconnectAttempts = 0;
  bool _reconnectEnabled = true;
  int? _lastAckErrorCode;
  String? _lastAckErrorMessage;
  DateTime? _lastAckErrorAt;
  bool _lastNetworkAvailable = true;
  bool _isFlushingOfflineOutbounds = false;

  final Map<String, _PendingOutbound> _pendingOutbounds = {};
  // 离线队列存储 base64 编码的二进制帧，便于持久化到 SharedPreferences
  final ListQueue<String> _offlineOutbounds = ListQueue<String>();

  late final StreamController<PacketFrame<IPacket>> _messageController;

  @override
  WsState build() {
    log.info('🌐 WsController 构建中...');

    _messageController = StreamController<PacketFrame<IPacket>>.broadcast();
    _restoreOfflineOutbounds();

    // 监听认证状态变化：登录时连接，登出时断开
    ref.listen(authControllerProvider, (previous, next) {
      log.info(
        '[WsController] auth 状态变更: prev=${previous?.value != null}, next=${next.value != null}, nextLoading=${next.isLoading}, nextHasError=${next.hasError}',
      );
      next.when(
        data: (user) {
          if (user != null) {
            log.info('[WsController] 检测到用户登录，准备连接...');
            _reconnectEnabled = true;
            _initConnection();
          } else {
            log.info('[WsController] 检测到用户退出，断开连接...');
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

    ref.listen(networkStatusProvider, (previous, next) {
      final statuses = next.value;
      if (statuses == null || statuses.isEmpty) return;

      final bool available = !statuses.contains(ConnectivityResult.none);
      final bool recovered = !_lastNetworkAvailable && available;
      _lastNetworkAvailable = available;

      if (recovered) {
        log.info('[WsController] 网络已恢复，主动触发连接恢复');
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
      log.warning('[WsController] 初始化失败：未找到 Token');
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
      final url = '${API.wsBaseUrl}$token';
      log.info('[WsController] 正在尝试建立 WebSocket 连接: $url');

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
      log.info('✅ WebSocket 连接成功');

      _startHeartbeat();
      _flushOfflineOutbounds();
    } catch (e, st) {
      log.error('❌ WebSocket 连接失败', e, st);
      _handleError(e);
    }
  }

  /// 发送二进制消息（V5 协议帧）
  void sendMessage(dynamic msg) {
    // 统一转换为 Uint8List
    final Uint8List? bytes = _toBytes(msg);
    if (bytes == null) return;

    final String b64 = base64.encode(bytes);

    if (state.status != WsStatus.connected) {
      _enqueueOfflineOutbound(b64);
      log.warning('尝试在未连接状态发送消息，已进入离线队列');
      return;
    }

    try {
      _cachePendingOutbound(b64, bytes);
      _channel?.sink.add(bytes);
    } catch (e) {
      log.error('发送消息失败', e);
    }
  }

  static Uint8List? _toBytes(dynamic msg) {
    if (msg is Uint8List) return msg;
    if (msg is List<int>) return Uint8List.fromList(msg);
    // 旧调用兼容（'ping' 等文本）——忽略，心跳已改为二进制帧
    return null;
  }

  void _cachePendingOutbound(String b64Payload, Uint8List bytes) {
    final seq = _extractSeqFromB64(b64Payload);
    if (seq == null || seq.isEmpty) return;
    _pendingOutbounds[seq] = _PendingOutbound(
      payload: b64Payload,
      bytes: bytes,
    );
  }

  /// 从 base64 编码的二进制帧中提取 clientMsgId（用作 seq key）
  String? _extractSeqFromPayload(String b64Payload) =>
      _extractSeqFromB64(b64Payload);

  String? _extractSeqFromB64(String b64) {
    try {
      final bytes = base64.decode(b64);
      final frame = FrameCodec.parse(Uint8List.fromList(bytes));
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

  void _enqueueOfflineOutbound(String payload) {
    final seq = _extractSeqFromPayload(payload);
    if (seq != null) {
      _offlineOutbounds.removeWhere((item) {
        final existingSeq = _extractSeqFromPayload(item);
        return existingSeq != null && existingSeq == seq;
      });
    }

    if (_offlineOutbounds.length >= _maxOfflineQueueSize) {
      _offlineOutbounds.removeFirst();
      log.warning('[WsController] 离线队列已满，丢弃最早的一条消息');
    }
    _offlineOutbounds.addLast(payload);
    unawaited(_persistOfflineOutbounds());
  }

  void _flushOfflineOutbounds() {
    if (_isFlushingOfflineOutbounds) return;
    if (_offlineOutbounds.isEmpty || state.status != WsStatus.connected) {
      return;
    }

    log.info('[WsController] 开始回放离线消息，数量=${_offlineOutbounds.length}');
    _isFlushingOfflineOutbounds = true;
    _flushNextOfflineBatch();
  }

  void _flushNextOfflineBatch() {
    if (_offlineOutbounds.isEmpty || state.status != WsStatus.connected) {
      _isFlushingOfflineOutbounds = false;
      return;
    }

    bool changed = false;
    int sentCount = 0;
    while (_offlineOutbounds.isNotEmpty &&
        state.status == WsStatus.connected &&
        sentCount < _offlineFlushBatchSize) {
      final b64 = _offlineOutbounds.removeFirst();
      changed = true;
      sentCount += 1;
      try {
        final bytes = Uint8List.fromList(base64.decode(b64));
        _cachePendingOutbound(b64, bytes);
        _channel?.sink.add(bytes);
      } catch (e) {
        _offlineOutbounds.addFirst(b64);
        log.error('[WsController] 回放离线消息失败，稍后重试', e);
        break;
      }
    }

    if (changed) {
      unawaited(_persistOfflineOutbounds());
    }

    if (_offlineOutbounds.isEmpty || state.status != WsStatus.connected) {
      _isFlushingOfflineOutbounds = false;
      return;
    }

    _offlineFlushTimer?.cancel();
    _offlineFlushTimer = Timer(
      _offlineFlushBatchInterval,
      _flushNextOfflineBatch,
    );
  }

  Future<void> _persistOfflineOutbounds() async {
    await SPUtil.instance.setStringList(
      StorageKeys.wsOfflineOutboundQueue,
      _offlineOutbounds.toList(),
    );
  }

  void _restoreOfflineOutbounds() {
    final cached = SPUtil.instance.getStringList(
      StorageKeys.wsOfflineOutboundQueue,
      defValue: const <String>[],
    );
    if (cached == null || cached.isEmpty) return;

    _offlineOutbounds.clear();
    final restored = cached.length > _maxOfflineQueueSize
        ? cached.sublist(cached.length - _maxOfflineQueueSize)
        : cached;

    for (final payload in restored) {
      final seq = _extractSeqFromPayload(payload);
      if (seq != null) {
        _offlineOutbounds.removeWhere((item) {
          final existingSeq = _extractSeqFromPayload(item);
          return existingSeq != null && existingSeq == seq;
        });
      }
      _offlineOutbounds.addLast(payload);
    }
  }

  Future<void> _clearOfflineOutbounds() async {
    _offlineOutbounds.clear();
    await SPUtil.instance.delete(StorageKeys.wsOfflineOutboundQueue);
  }

  /// 处理接收到的消息（V5 二进制帧）
  void _handleIncomingMessage(dynamic message) {
    // 只处理二进制帧
    if (message is! List<int>) {
      log.warning('[WsController] 收到非二进制消息，忽略');
      return;
    }
    final bytes = Uint8List.fromList(message);
    log.info('[SERVER FRAME]: ${bytes.length} bytes');

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

      // ACK 帧：特殊处理
      if (decoded.isAck) {
        final ack = ImPacketV5.decodeAck(payload);
        if (ack != null) {
          // 打印 ACK 详情
          log.info('[SERVER ACK] 收到确认帧 -> Topic: $topic, ACK内容: $ack');
          _handleAckV5(ack);
        }
        return;
      }

      final packetData = PacketRegistry.parse(topic, payload, decoded.codecId);
      if (packetData != null) {
        // 打印解析后的具体业务数据内容
        log.info('[SERVER DATA] 解析成功 -> Topic: $topic, Content: $packetData');

        final frame = PacketFrame(topic: topic, data: packetData);
        if (!_messageController.isClosed) {
          _messageController.add(frame);
        }
      } else {
        // 💡 新增：兜底日志，防止注册表未识别该 topic
        log.warning('[SERVER DATA] 解析失败（未知的 Topic 或解析器缺失）-> Topic: $topic');
      }
    } catch (e) {
      log.error('WS 消息解析异常', e);
    }
  }

  /// 处理 V5 ACK
  void _handleAckV5(AckV5 ack) {
    final seq = ack.clientMessageId;
    if (ack.isSuccess) {
      if (seq != null && seq.isNotEmpty) {
        _pendingOutbounds.remove(seq);
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
        _pendingOutbounds.remove(seq);
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
      Toast.showToast(
        _resolveAckErrorMessage(code, rawMessage),
        type: ToastType.error,
      );
    }
    log.warning('[WsController] ACK业务失败: code=$code, message=$rawMessage');
  }

  void _retryPendingOutbound(String seq) {
    final pending = _pendingOutbounds[seq];
    if (pending == null) return;
    if (pending.retryScheduled) return;

    if (pending.attempts >= _maxAutoRetryAttempts) {
      _pendingOutbounds.remove(seq);
      log.warning('[WsController] 自动重试超过上限，放弃: seq=$seq');
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
        _pendingOutbounds.remove(seq);
        log.warning('[WsController] 自动重试超过上限(延迟触发)，放弃: seq=$seq');
        return;
      }

      try {
        _channel?.sink.add(pending.bytes);
        log.warning(
          '[WsController] 已触发自动重试: seq=$seq, attempt=${pending.attempts}',
        );
      } catch (e) {
        log.error('[WsController] 自动重试发送失败: seq=$seq', e);
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
    log.info('WebSocket 连接关闭: closeCode=$closeCode, closeReason=$closeReason');
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
    log.warning('将在 $delaySeconds 秒后进行第 ${_reconnectAttempts + 1} 次重连...');

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
      '[WsController] 执行断开: closeStream=$closeStream, manual=$manual, state=${state.status}',
    );
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _offlineFlushTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _pendingOutbounds.clear();
    if (manual && !closeStream) {
      unawaited(_clearOfflineOutbounds());
    }
    _reconnectAttempts = 0;
    if (closeStream) {
      _messageController.close();
    }
    state = WsState(status: WsStatus.disconnected);
  }
}

class _PendingOutbound {
  _PendingOutbound({required this.payload, required this.bytes});

  final String payload; // base64 编码，用于离线持久化
  final Uint8List bytes; // 原始二进制，用于重试发送
  int attempts = 0;
  bool retryScheduled = false;
}

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息
@riverpod
Stream<PacketFrame<IPacket>> wsMessageStream(Ref ref) {
  final wsController = ref.read(wsControllerProvider.notifier);
  return wsController.messageStream;
}
