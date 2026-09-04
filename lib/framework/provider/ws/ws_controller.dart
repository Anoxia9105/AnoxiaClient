import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/core/device_identity.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/constants/api.dart';
import '../../codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../../protocol/message/event_message.dart';
import '../../protocol/message/high_message.dart';
import '../../protocol/message/room_message.dart';
import '../../protocol/message/message_enum.dart';
import '../../protocol/packet_type.dart';
import '../../network/token_manager.dart';
import '../../protocol/i_packet.dart';
import '../../protocol/packet_frame.dart';
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

  /// 当前连接（含正在建立的连接）所使用的认证 token。
  ///
  /// 用于识别「切换账号」场景：切账号时认证态从 Data(A) 直接变为
  /// Data(B)，不会经过 null，若仅按连接状态判断会一直复用旧账号
  /// 的连接，导致消息被服务端记到上一个账号名下（服务端以握手
  /// token 绑定的身份为准），且新账号独有的房间会报「用户不在房间内」。
  String? _connectedToken;

  /// 连接代际计数：每次发起连接/主动断开时自增。
  ///
  /// 用于丢弃过期的连接尝试（如连续切换账号时，旧 token 的握手
  /// 在新连接建立后才完成，不允许其覆盖当前连接或污染状态）。
  int _connectGeneration = 0;
  Timer? _reconnectTimer;
  Timer? _readCursorTimer;
  Timer? _messageRecoveryTimer;
  bool _flushingReadCursors = false;
  int _reconnectAttempts = 0;
  bool _reconnectEnabled = true;
  int? _lastAckErrorCode;
  String? _lastAckErrorMessage;
  DateTime? _lastAckErrorAt;
  bool _lastNetworkAvailable = true;

  final Map<String, _PendingOutbound> _pendingOutbounds = {};
  final Map<String, _PendingCommand> _pendingCommands = {};

  late final StreamController<PacketFrame<IPacket>> _messageController;

  @override
  WsState build() {
    _messageController = StreamController<PacketFrame<IPacket>>.broadcast();

    // 监听认证状态变化：登录时连接，登出时断开
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            _reconnectEnabled = true;
            _initConnection();
          } else {
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
  ///
  /// 已有连接时：token 未变化则跳过；token 变化（切换账号）则先断开
  /// 旧账号连接，再以新 token 重建。
  Future<void> _initConnection() async {
    final token = await TokenManager.instance.getToken();
    if (token == null || token.isEmpty) {
      debugLog('[WsController] 初始化失败：未找到 Token');
      return;
    }

    if (state.status == WsStatus.connecting ||
        state.status == WsStatus.connected) {
      // 身份未变化，无需重连
      if (_connectedToken == token) {
        return;
      }
      // 切换账号：旧连接仍是上一个账号的会话，必须先断开再重建，
      // 否则服务端仍按旧身份收发消息。
      debugLog('[WsController] 检测到 token 变化，断开旧连接并以新身份重连');
      await _disposeAll(closeStream: false, manual: true);
    }

    await connect(token);
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
    // 先同步记录本次连接使用的身份与代际，供 _initConnection 的
    // 切账号判断使用；代际用于识别本尝试是否已被更新的操作取代。
    _connectedToken = token;
    final generation = ++_connectGeneration;

    try {
      final deviceId = await DeviceIdentity.instance.getPlatformQualifiedId();
      final url =
          '${API.wsBaseUrl}${Uri.encodeQueryComponent(token)}'
          '&deviceId=${Uri.encodeQueryComponent(deviceId)}';

      final WebSocketChannel channel;
      if (kIsWeb) {
        channel = WebSocketChannel.connect(Uri.parse(url));
      } else {
        // 桌面端关闭压缩扩展协商，避免部分代理链路下触发 1002(PROTOCOL_ERROR)
        final socket = await io.WebSocket.connect(
          url,
          compression: io.CompressionOptions.compressionOff,
        );
        channel = IOWebSocketChannel(socket);
      }
      await channel.ready;

      // 握手期间发生了切账号/主动断开：本次连接已过期，直接丢弃，
      // 不登记为当前连接、不触发重连逻辑。
      if (generation != _connectGeneration || !_reconnectEnabled) {
        try {
          await channel.sink.close();
        } catch (_) {}
        debugLog('[WsController] 丢弃过期的连接尝试 (generation=$generation)');
        return;
      }

      // 握手成功后才登记为当前连接，避免半途被 _disposeAll 的旧
      // channel 覆盖新的 _channel。
      _channel = channel;

      channel.stream.listen(
        (message) => _handleIncomingMessage(message),
        onError: (err) => _handleError(err),
        onDone: () => _handleDone(),
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      state = WsState(status: WsStatus.connected);
      unawaited(_resendCachedOutbounds());
      _readCursorTimer?.cancel();
      _readCursorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(flushReadCursors());
      });
      unawaited(flushReadCursors());
      _messageRecoveryTimer?.cancel();
      _messageRecoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        unawaited(_recoverActiveRoom());
      });
      unawaited(_recoverActiveRoom());
    } catch (e, st) {
      debugLog('❌ WebSocket 连接失败', e, st);
      // 过期尝试的失败不影响更新的连接状态（如连续切账号时旧
      // token 握手超时，不应打断新 token 已建立的连接）。
      if (generation == _connectGeneration) {
        _handleError(e);
      }
    }
  }

  /// 定期补齐活跃会话，包括没有后续消息暴露的尾部丢包。
  Future<void> _recoverActiveRoom() async {
    if (!ref.mounted || state.status != WsStatus.connected) return;
    final roomId = ref.read(activeRoomIdProvider);
    if (roomId == null) return;
    try {
      // Pub/Sub/慢消费者可能丢最后一条，没有后续 seq 也必须能恢复。
      await ref.read(chatRepositoryProvider).syncMessages(roomId);
    } catch (e) {
      debugLog('活跃会话补齐失败: $e');
    }
  }

  Future<void> flushReadCursors() async {
    if (!ref.mounted ||
        state.status != WsStatus.connected ||
        _flushingReadCursors) {
      return;
    }
    _flushingReadCursors = true;
    final generation = _connectGeneration;
    final local = ref.read(localDataSourceProvider);
    bool isCurrent() =>
        ref.mounted &&
        generation == _connectGeneration &&
        state.status == WsStatus.connected;
    try {
      final pending = await local.pendingReadCursors();
      for (final entry in pending.entries) {
        if (!isCurrent()) break;
        final requestId =
            'read_${DateTime.now().microsecondsSinceEpoch}_${entry.key}';
        try {
          final ack = await sendCommand(
            ImPacketV6.encodeReadCursorFrame(
              entry.key,
              entry.value,
              requestId: requestId,
            ),
            requestId: requestId,
          );
          if (!isCurrent()) break;
          if (ack.isSuccess) {
            await local.acknowledgeReadCursor(entry.key, entry.value);
          }
        } catch (e) {
          debugLog('已读游标待重试: $e');
        }
      }
    } catch (e) {
      debugLog('读取已读待确认队列失败: $e');
    } finally {
      _flushingReadCursors = false;
    }
  }

  /// 发送 V6 ClientFrame 原始二进制负载。
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
      if (clientMsgId != null && clientMsgId.isNotEmpty) {
        _cachePendingOutbound(
          bytes,
          clientMsgId: clientMsgId,
          ackTimeout: ackTimeout,
        );
      }
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

  /// 发送需要业务 ACK 的 V6 命令（例如撤回）。
  Future<AckV6> sendCommand(
    Uint8List bytes, {
    required String requestId,
    Duration timeout = _defaultAckTimeout,
  }) {
    if (state.status != WsStatus.connected) {
      return Future.error(StateError('WebSocket is not connected'));
    }
    final existing = _pendingCommands.remove(requestId);
    existing?.timeoutTimer.cancel();
    existing?.completer.completeError(StateError('Command replaced'));

    final completer = Completer<AckV6>();
    final timer = Timer(timeout, () {
      final pending = _pendingCommands.remove(requestId);
      pending?.completer.completeError(
        TimeoutException('V6 command ACK timeout'),
      );
    });
    _pendingCommands[requestId] = _PendingCommand(completer, timer);
    try {
      _channel!.sink.add(bytes);
    } catch (error, stackTrace) {
      _pendingCommands.remove(requestId);
      timer.cancel();
      completer.completeError(error, stackTrace);
    }
    return completer.future;
  }

  static Uint8List? _toBytes(dynamic msg) {
    if (msg is Uint8List) return msg;
    if (msg is List<int>) return Uint8List.fromList(msg);
    return null;
  }

  void _cachePendingOutbound(
    Uint8List bytes, {
    required String clientMsgId,
    required Duration ackTimeout,
  }) {
    final seq = clientMsgId;
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

  /// 处理 V6 ServerFrame 原始二进制负载。
  void _handleIncomingMessage(dynamic message) {
    if (message is! List<int>) {
      debugLog('[WsController] 收到非二进制消息，忽略');
      return;
    }
    final bytes = message is Uint8List ? message : Uint8List.fromList(message);

    final v6Decoded = ImPacketV6.decodeServerFrame(bytes);
    if (v6Decoded != null) {
      _dispatchV6(v6Decoded);
      return;
    }
    debugLog('[WsController] 无法解析 V6 ServerFrame，忽略');
  }

  void _dispatchV6(DecodedV6 decoded) {
    try {
      switch (decoded.type) {
        case 'message':
          final rm = decoded.data as RoomMessage;
          final frame = PacketFrame(topic: PacketType.message, data: rm);
          if (!_messageController.isClosed) _messageController.add(frame);
          break;
        case 'ack':
          final ack = decoded.data as AckV6;
          _handleAckV6(ack, decoded.requestId);
          break;
        case 'error':
          final msg = decoded.errorMessage ?? 'unknown error';
          debugLog(
            '[WsController] V6 ProtocolError: code=${decoded.errorCode} msg=$msg',
          );
          ref
              .read(toastServiceProvider)
              .showToast(
                msg.isNotEmpty ? msg : 'chat_send_failed_generic'.tr(),
                type: ToastType.error,
              );
          // 若关联 pending，则标记失败
          final rid = decoded.requestId;
          if (rid != null && rid.isNotEmpty) {
            final command = _pendingCommands.remove(rid);
            if (command != null) {
              command.timeoutTimer.cancel();
              command.completer.completeError(StateError(msg));
              break;
            }
            _removePendingOutbound(rid);
            ref
                .read(chatMessagesProvider.notifier)
                .markFailedByClientMsgId(rid);
          }
          break;
        case 'callSignal':
        case 'typing':
        case 'systemKick':
          final hm = decoded.data as HighMessage;
          final callFrame = PacketFrame(
            topic: PacketType.highFrequency,
            data: hm,
          );
          if (!_messageController.isClosed) _messageController.add(callFrame);
          break;
        case 'event':
          final eventMsg = decoded.data as EventMessage;
          final evFrame = PacketFrame(topic: PacketType.event, data: eventMsg);
          if (!_messageController.isClosed) _messageController.add(evFrame);
          break;
        case 'operation':
          final op = decoded.data as Map<String, dynamic>;
          final opType = op['type'] as int? ?? 0;
          final roomId = op['roomId'] as String? ?? '';
          final messageId = op['messageId'] as String? ?? '';
          // 1=RECALLED, 2=EDITED, 3=DELETED_FOR_ALL, 4=DELETED_FOR_SELF
          if (opType == 1 || opType == 3) {
            // 消息撤回/删除，本地删除
            if (messageId.isNotEmpty && roomId.isNotEmpty) {
              ref
                  .read(chatMessagesProvider.notifier)
                  .removeMessage(messageId, roomId);
            }
          }
          debugLog('[WsController] V6 operation: $op');
          break;
      }
    } catch (e, st) {
      debugLog('WS V6 分发异常', e, st);
    }
  }

  void _handleAckV6(AckV6 ack, String? requestId) {
    if (requestId != null) {
      final command = _pendingCommands.remove(requestId);
      if (command != null) {
        command.timeoutTimer.cancel();
        command.completer.complete(ack);
        return;
      }
    }
    final seq = requestId ?? ack.clientMessageId;
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
    final duplicated =
        _lastAckErrorCode == code &&
        _lastAckErrorMessage == rawMessage &&
        _lastAckErrorAt != null &&
        now.difference(_lastAckErrorAt!) < const Duration(seconds: 2);
    if (!duplicated) {
      _lastAckErrorCode = code;
      _lastAckErrorMessage = rawMessage;
      _lastAckErrorAt = now;
      ref
          .read(toastServiceProvider)
          .showToast(
            rawMessage.isNotEmpty
                ? rawMessage
                : 'chat_send_failed_generic'.tr(),
            type: ToastType.error,
          );
    }
    debugLog('[WsController] V6 ACK业务失败: code=$code, message=$rawMessage');
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
      } catch (e) {
        debugLog('[WsController] 自动重试发送失败: seq=$seq', e);
      }
    });
  }

  /// 连接恢复后把 Drift 中的待发送消息重新编码为当前 V6 ClientFrame。
  ///
  /// 缓存只保存协议无关的领域消息，不保存旧 wire bytes，因此重连后不会
  /// 重放过期协议帧；同一个 clientMsgId 继续承担 V6 幂等与 ACK 关联键。
  Future<void> _resendCachedOutbounds() async {
    try {
      final pending = await ref
          .read(localDataSourceProvider)
          .pendingOutgoingMessages();
      for (final message in pending) {
        if (state.status != WsStatus.connected) return;
        final roomId = message.roomId;
        final clientMsgId = message.clientMsgId ?? message.messageId;
        if (roomId == null ||
            roomId.isEmpty ||
            clientMsgId == null ||
            clientMsgId.isEmpty) {
          continue;
        }

        final sending = message.copyWith(
          clientMsgId: clientMsgId,
          deliveryStatus: DeliveryStatus.sending,
        );
        ref.read(chatMessagesProvider.notifier).upsertMessage(sending);
        final packet = RoomMessage(
          messageId: '',
          clientMsgId: clientMsgId,
          roomId: roomId,
          senderId: message.senderId ?? 0,
          messageType: message.messageType ?? MessageType.text,
          payload: message.payload,
          clientTimestamp:
              message.timestamp ?? DateTime.now().millisecondsSinceEpoch,
        );
        sendMessage(
          ImPacketV6.encodeRoomMessageFrame(packet),
          clientMsgId: clientMsgId,
        );
      }
    } catch (error, stackTrace) {
      debugLog('[WsController] V6 本地待发送队列恢复失败', error, stackTrace);
    }
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
    _reconnectTimer?.cancel();

    if (!_reconnectEnabled) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final delaySeconds = _calculateReconnectDelay();

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
    _reconnectTimer?.cancel();
    _readCursorTimer?.cancel();
    _messageRecoveryTimer?.cancel();
    // 代际自增：使仍在握手的连接尝试失效，防止其登记为当前连接
    _connectGeneration++;
    final channel = _channel;
    _channel = null;
    _connectedToken = null;
    for (final pending in _pendingOutbounds.values) {
      pending.timeoutTimer?.cancel();
    }
    _pendingOutbounds.clear();
    for (final pending in _pendingCommands.values) {
      pending.timeoutTimer.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(StateError('WebSocket disconnected'));
      }
    }
    _pendingCommands.clear();
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

class _PendingCommand {
  const _PendingCommand(this.completer, this.timeoutTimer);

  final Completer<AckV6> completer;
  final Timer timeoutTimer;
}

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息
@riverpod
Stream<PacketFrame<IPacket>> wsMessageStream(Ref ref) {
  final wsController = ref.read(wsControllerProvider.notifier);
  return wsController.messageStream;
}
