import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// IMWebSocketService
///
/// - cross-platform: 基于 web_socket_channel，兼容 web / native
/// - reconnect: 自动重连（指数退避 + 抖动）
/// - heartbeat: 应用层心跳（默认 30s），若一定时间内未收到消息或 pong，则自动重连
/// - pub/sub: 基于消息中 `topic` 字段进行订阅（也可订阅全部消息）
class IMClient {
  /// WebSocket 地址（wss:// 或 ws://）
  final String url;

  /// 心跳间隔（发送 ping 的周期），默认 30 秒
  final Duration heartbeatInterval;

  /// 在检测到心跳超时后，判定为连接失效的阈值（建议 >= heartbeatInterval * 2）
  final Duration heartbeatTimeout;

  /// 重连初始延迟（用于指数退避），默认 2 秒
  final Duration reconnectInitialDelay;

  /// 重连最大延迟，防止指数退避无限增长，默认 120 秒
  final Duration reconnectMaxDelay;

  /// 是否在意外断开后自动重连（若 false，需要手动调用 connect()）
  final bool autoReconnect;

  /// 最大重连次数，<=0 表示无限次
  final int maxReconnectAttempts;

  /// 自定义 ping 消息（用于应用层心跳），默认 {'type':'ping'}
  final dynamic pingMessage;

  /// 服务器端对应的 pong 判定（可为字符串或函数）
  /// 如果 pongMatcher 是字符串，则判断消息 == pongMatcher
  /// 如果是函数，则调用 pongMatcher(msg) -> bool
  final dynamic pongMatcher;

  /// 可选：自定义消息序列化/反序列化
  final String Function(dynamic msg)? encoder;
  final dynamic Function(String raw)? decoder;

  // --- 内部状态 ---
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastReceivedAt;
  bool _manuallyDisconnected = false;
  bool _connecting = false;
  int _reconnectAttempts = 0;

  // 缓冲区：未连接时发送的消息会被缓存并在连接建立后发送
  final List<dynamic> _sendBuffer = [];

  // 入站消息广播流，所有消息（解码后）会发到此 stream
  final StreamController<dynamic> _inboundController = StreamController<dynamic>.broadcast();

  // 公开的 inbound stream（只读）
  Stream<dynamic> get inboundStream => _inboundController.stream;

  // 连接 / 断开 / 错误 回调（可选）
  void Function()? onConnect;
  void Function()? onDisconnect;
  void Function(Object error)? onError;
  void Function(dynamic message)? onMessage;

  IMClient({
    required this.url,
    this.heartbeatInterval = const Duration(seconds: 30),
    Duration? heartbeatTimeout,
    this.reconnectInitialDelay = const Duration(seconds: 2),
    this.reconnectMaxDelay = const Duration(seconds: 120),
    this.autoReconnect = true,
    this.maxReconnectAttempts = 0,
    this.pingMessage = 'ping',
    this.pongMatcher = 'pong',
    this.encoder,
    this.decoder,
  }) : heartbeatTimeout = heartbeatTimeout ?? heartbeatInterval * 2;

  // ---------------- 外部 API ----------------

  /// 建立连接（显式调用）。如果已连接，则跳过。
  Future<void> connect() async {
    if (_channel != null) {
      // 已连接（或正在连接）
      return;
    }
    _manuallyDisconnected = false;
    await _internalConnect();
  }

  /// 断开连接（并阻止自动重连）
  Future<void> disconnect({int closeCode = status.normalClosure, String? reason}) async {
    _manuallyDisconnected = true;
    _cancelReconnectTimer();
    _stopHeartbeat();
    try {
      await _channel?.sink.close(closeCode, reason);
    } catch (_) {}
    _channel = null;
    _inboundController.add({'event': 'disconnected'});
    onDisconnect?.call();
  }

  /// 发送消息（若未连接则缓存）
  /// msg 可以是 String / Map / List / bytes
  Future<void> send(dynamic msg) async {
    final payload = encoder != null
        ? encoder!(msg)
        : (msg is String ? msg : jsonEncode(msg));

    if (_channel == null) {
      _sendBuffer.add(payload);
      return;
    }

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      _sendBuffer.add(payload);
      _handleError(e);
    }
  }

  /// 订阅某个 topic（假定消息是 Map 并包含 'topic' 字段）
  /// 返回 StreamSubscription，调用 cancel() 即可取消订阅
  StreamSubscription<dynamic> subscribeTopic(String topic, void Function(dynamic msg) onData) {
    return inboundStream.where((msg) {
      if (msg is Map) {
        return msg['topic'] == topic;
      }
      return false;
    }).listen((msg) {
      try {
        onData(msg);
      } catch (e) {
        // 忽略订阅处理中的异常，防止影响其他订阅
      }
    });
  }

  /// 订阅所有消息
  StreamSubscription<dynamic> subscribeAll(void Function(dynamic msg) onData) {
    return inboundStream.listen((msg) {
      try {
        onData(msg);
      } catch (e) {}
    });
  }

  /// 当前是否处于连接状态
  bool get isConnected => _channel != null;

  /// 关闭并释放资源（不可再用）
  Future<void> dispose() async {
    _manuallyDisconnected = true;
    _cancelReconnectTimer();
    _stopHeartbeat();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _inboundController.close();
  }

  // ---------------- 内部实现 ----------------

  Future<void> _internalConnect() async {
    if (_connecting) return;
    _connecting = true;
    try {
      // 创建连接
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 监听入站数据
      _channel!.stream.listen(
            (dynamic raw) => _onRawMessage(raw),
        onError: (error) => _onSocketError(error),
        onDone: () => _onSocketDone(),
        cancelOnError: true,
      );

      // 连接建立成功
      _reconnectAttempts = 0;
      _lastReceivedAt = DateTime.now();
      _startHeartbeat();
      _flushSendBuffer();
      onConnect?.call();
      _inboundController.add({'event': 'connected'});
    } catch (e) {
      // 连接失败，触发重连
      _handleError(e);
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  // 处理原始消息，尝试解码并派发
  void _onRawMessage(dynamic raw) {
    _lastReceivedAt = DateTime.now();

    dynamic message = raw;
    try {
      if (decoder != null && raw is String) {
        message = decoder!(raw);
      } else if (raw is String) {
        // 尝试 JSON decode
        message = jsonDecode(raw);
      }
    } catch (_) {
      // 非 JSON，保留原始字符串
      message = raw;
    }

    // 应答 pong（如果消息匹配 pongMatcher 则认为心跳收到）
    bool isPong = _matchPong(message);
    if (isPong) {
      // 仅更新 lastReceivedAt 即可
      return;
    }

    // 派发到 inbound stream
    _inboundController.add(message);
    onMessage?.call(message);
  }

  bool _matchPong(dynamic message) {
    if (pongMatcher == null) return false;
    if (pongMatcher is String) {
      return message == pongMatcher;
    } else if (pongMatcher is Map && message is Map) {
      // 简单 Map 子集匹配
      for (final key in (pongMatcher as Map).keys) {
        if (message[key] != (pongMatcher as Map)[key]) return false;
      }
      return true;
    } else if (pongMatcher is bool Function(dynamic)) {
      try {
        return (pongMatcher as bool Function(dynamic))(message);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  // socket 错误
  void _onSocketError(Object error) {
    _handleError(error);
    _scheduleReconnect();
  }

  // socket 正常关闭（onDone）
  void _onSocketDone() {
    _stopHeartbeat();
    _channel = null;
    _inboundController.add({'event': 'disconnected'});
    onDisconnect?.call();
    if (!_manuallyDisconnected && autoReconnect) {
      _scheduleReconnect();
    }
  }

  void _handleError(Object error) {
    onError?.call(error);
    _inboundController.add({'event': 'error', 'error': error});
  }

  // 启动应用层心跳定时器
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      // 1) 检查收包时间，若超过 heartbeatTimeout 则认为连接失效并重连
      final last = _lastReceivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final now = DateTime.now();
      if (now.difference(last) > heartbeatTimeout) {
        // 心跳超时
        try {
          await _forceReconnect();
        } catch (_) {}
        return;
      }

      // 2) 发送 ping（应用层）
      try {
        await send(pingMessage);
      } catch (e) {
        _handleError(e);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // 将缓冲区消息发送出去
  void _flushSendBuffer() {
    if (_channel == null) return;
    while (_sendBuffer.isNotEmpty) {
      final payload = _sendBuffer.removeAt(0);
      try {
        _channel!.sink.add(payload);
      } catch (e) {
        // 发送失败则重新入队并退出
        _sendBuffer.insert(0, payload);
        break;
      }
    }
  }

  // 强制立即重连（取消旧连接、停止心跳，并立即尝试 connect）
  Future<void> _forceReconnect() async {
    _cancelReconnectTimer();
    _stopHeartbeat();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _internalConnect();
  }

  // 计划重连（指数退避 + 抖动）
  void _scheduleReconnect() {
    if (!autoReconnect) return;
    if (_reconnectTimer != null) return; // 已经计划了重连

    _reconnectAttempts++;
    if (maxReconnectAttempts > 0 && _reconnectAttempts > maxReconnectAttempts) {
      // 超过最大尝试次数，停止重连
      _inboundController.add({'event': 'reconnect_failed'});
      return;
    }

    final baseMs = reconnectInitialDelay.inMilliseconds * pow(2, _reconnectAttempts - 1);
    final capped = min(baseMs, reconnectMaxDelay.inMilliseconds);
    // 加上一点随机抖动，避免多客户端同时重连造成风暴
    final jitter = Random().nextInt(1000); // 0-999ms
    final delayMs = capped + jitter;
    _reconnectTimer = Timer(Duration(milliseconds: int.parse(delayMs.toString())), () async {
      _reconnectTimer = null;
      await _internalConnect();
    });
    _inboundController.add({
      'event': 'reconnect_scheduled',
      'attempt': _reconnectAttempts,
      'delayMs': delayMs,
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }
}
