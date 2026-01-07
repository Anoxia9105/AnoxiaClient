import 'dart:async';
import 'dart:math';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/IMEvent.dart';
import '../enums/IMEventType.dart';

/// IMClient
///
/// 设计目标（概览）：
///  - 使用 `web_socket_channel` 实现跨平台 WS（支持 web / native）
///  - 自动重连：指数退避 + 抖动（可配置最大尝试次数）
///  - 应用层心跳（ping/pong）：可自定义 ping 消息及 pong 匹配器
///  - 入站广播（StreamController.broadcast），支持按 topic 订阅或订阅全部
///  - 发送缓冲（连接未建立或发送失败时缓存）
class IMClient {
  // ------------- 配置字段 -------------
  /// WebSocket 地址（必须是 ws:// 或 wss://）
  final String url;

  /// 应用层心跳间隔（发送 ping 的周期），默认 30s
  final Duration heartbeatInterval;

  /// 心跳超时时间阈值（若超过该时间未收到任何消息，则认为连接失效），建议 >= heartbeatInterval * 2
  final Duration heartbeatTimeout;

  /// 重连的初始延迟（指数退避的基数），默认 2s
  final Duration reconnectInitialDelay;

  /// 重连最大延迟（防止无限增长），默认 120s
  final Duration reconnectMaxDelay;

  /// 是否在意外断开后自动重连
  final bool autoReconnect;

  /// 最大重连尝试次数，<=0 表示无限次
  final int maxReconnectAttempts;

  /// 自定义 ping 消息（应用层），默认使用 'ping'
  /// 支持 String / Map / List<int> 等任意可通过 sink.add 发送的类型
  final dynamic pingMessage;

  /// 自定义编码器（发送前将 msg -> String|List<int>等）。若为 null，默认会：
  ///  - 如果 msg 是 String/Uint8List/List<int> -> 直接使用
  ///  - 否则使用 jsonEncode
  final String Function(dynamic msg)? encoder;

  /// 自定义解码器（收到 raw String -> 返回具体对象）。若为 null，会尝试 jsonDecode
  final dynamic Function(String raw)? decoder;

  /// 是否把 pong 转发到 inboundStream（默认为 false，若你需要业务观察 pong，则设为 true）
  final bool forwardPong;

  /// 可选的日志回调（便于线上追踪）
  final void Function(String tag, String message)? logger;

  // ------------- 内部状态字段 -------------
  WebSocketChannel? _channel;

  // 心跳 Timer（用于周期发送 ping）
  Timer? _heartbeatTimer;

  // 重连计时器
  Timer? _reconnectTimer;

  // 手动断开标志（用于区分意外断开与主动断开）
  bool _manuallyDisconnected = false;

  // 连接中的标志（防止重复发起 connect），与 _channel 不同步使用是为了避免竞态
  bool _connecting = false;

  // 已尝试的重连次数（从 1 开始递增）
  int _reconnectAttempts = 0;

  // 发送缓冲区：采用 Queue，便于高效出入队
  // final Queue<dynamic> _sendBuffer = Queue<dynamic>();

  // 入站广播流：所有收到（并解码后）的消息都会发到这个 stream
  final StreamController<IMEvent> _inboundController = StreamController<IMEvent>.broadcast();

  // 公开只读 inbound stream
  Stream<dynamic> get inboundStream => _inboundController.stream;

  // 是否正在执行缓冲区刷新（避免重入）
  bool _isFlushing = false;

  IMClient({
    required this.url,
    this.heartbeatInterval = const Duration(seconds: 30),
    Duration? heartbeatTimeout,
    this.reconnectInitialDelay = const Duration(seconds: 2),
    this.reconnectMaxDelay = const Duration(seconds: 120),
    this.autoReconnect = true,
    this.maxReconnectAttempts = 0,
    this.pingMessage = 'ping',
    this.encoder,
    this.decoder,
    this.forwardPong = false,
    this.logger,
  }) : heartbeatTimeout = heartbeatTimeout ?? (heartbeatInterval * 2);

  // ---------------- 外部 API ----------------

  /// 建立连接（显式调用）。如果已经在连接中或已连接则直接返回。
  Future<void> connect() async {
    // 幂等判断：如果正在连接或已经有 channel，就不再发起第二次连接
    if (_channel != null || _connecting) {
      logger?.call(
        'connect',
        'connect() called but already connected/connecting.',
      );
      return;
    }
    _manuallyDisconnected = false;
    await _internalConnect();
  }

  /// 断开连接（并阻止自动重连）
  ///
  /// closeCode/ reason 会传到底层 socket 的 close。
  Future<void> disconnect({
    int closeCode = status.normalClosure,
    String? reason,
  }) async {
    _manuallyDisconnected = true;
    _cancelReconnectTimer();
    _stopHeartbeat();

    try {
      // 可能抛异常，catch 掉，保证内部状态一致
      await _channel?.sink.close(closeCode, reason);
    } catch (e) {
      // 忽略关闭异常，但记录
      logger?.call('disconnect', 'close error: $e');
    }
    _channel = null;

    // 在断开时发一个事件（若 stream 已关闭会抛，但通常不会在 disconnect 调用后立刻 close stream）
    if (!_inboundController.isClosed) {
      // 断开
      _inboundController.add(IMEvent(IMEventType.disconnected));
    }
  }

  /// 发送消息（若未连接则缓存）
  ///
  /// 支持 String、Map、List、Uint8List（bytes）等。
  Future<void> send(String msg) async {
    try {
      _channel!.sink.add(msg);
    } catch (e) {
      _handleError(e);
    }
  }

  /// 订阅某个 topic（假定消息是 Map 并包含 'topic' 字段）
  StreamSubscription<dynamic> subscribeTopic(
    String topic,
    void Function(dynamic msg) onData,
  ) {
    return inboundStream
        .where((msg) {
          if (msg is Map) {
            return msg['topic'] == topic;
          }
          return false;
        })
        .listen((msg) {
          try {
            onData(msg);
          } catch (e) {
            // 忽略订阅处理中的异常，防止影响其他订阅
            logger?.call('subscribeTopic', 'subscriber throw: $e');
          }
        });
  }

  /// 订阅所有消息
  StreamSubscription<dynamic> subscribeAll(void Function(IMEvent msg) onData) {
    return inboundStream.listen((msg) {
      try {
        onData(msg);
      } catch (e) {
        logger?.call('subscribeAll', 'subscriber throw: $e');
      }
    });
  }

  /// 当前是否处于连接状态（粗略判断）
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
    // 关闭 inbound stream
    await _inboundController.close();
  }

  // ---------------- 内部实现 ----------------

  /// 内部连接实现
  Future<void> _internalConnect() async {
    if (_connecting) return;
    _connecting = true;

    try {
      logger?.call('connect', 'attempting to connect to $url');

      // 建立连接：WebSocketChannel.connect 在 web & native 都可用（取决于 package 使用）
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 监听入站数据
      _channel!.stream.listen(
        // 处理原始消息（解码、pong 匹配、派发）
        (dynamic raw){
          print("SOCKET::::::::::$raw");
          if(!_inboundController.isClosed){
            _inboundController.add(IMEvent(IMEventType.message, data: raw));
          }
        },
        onError: (error) => _onSocketError(error),
        onDone: () => _onSocketDone(),
        cancelOnError: true,
      );

      // 连接建立成功，重置计数
      _reconnectAttempts = 0;

      // 启动心跳
      _startHeartbeat();

      // 连接成功
      if (!_inboundController.isClosed) {
        _inboundController.add(IMEvent(IMEventType.connected));
      }
      logger?.call('connect', 'connected to $url');
    } catch (e) {
      // 连接失败，触发错误与重连
      _handleError(e);
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  // socket 错误处理回调
  void _onSocketError(Object error) {
    _handleError(error);
    // 出现 socket 错误时，确保尝试重连（如果配置允许）
    _scheduleReconnect();
  }

  // socket 正常关闭（onDone）
  void _onSocketDone() {
    logger?.call('socket', 'onDone called');
    _stopHeartbeat();
    _channel = null;

    if (!_inboundController.isClosed) {
      // 断开
      _inboundController.add(IMEvent(IMEventType.disconnected));
    }

    if (!_manuallyDisconnected && autoReconnect) {
      _scheduleReconnect();
    }
  }

  // 中央错误处理：通知回调并在 inbound stream 中发布 error event
  void _handleError(Object error) {
    // 发送到 inbound stream 作为结构化事件，便于监听器统一处理
    if (!_inboundController.isClosed) {
      // 错误
      _inboundController.add(IMEvent(IMEventType.error, data: error));
    }
    logger?.call('error', '$error');
  }

  // 启动心跳定时器：周期发送 ping 并检测超时
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
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

  // 将缓冲区消息发送出去（非阻塞）
  void _flushSendBuffer() {
    // 防止重入
    if (_isFlushing) return;
    _isFlushing = true;

    if (_channel == null) {
      _isFlushing = false;
      return;
    }

    _isFlushing = false;
  }

  // 强制立即重连（取消旧连接并立即尝试 connect）
  Future<void> _forceReconnect() async {
    _cancelReconnectTimer();
    _stopHeartbeat();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    // 立刻发起连接（注意：此处不检查 _connecting，确保尽快恢复）
    await _internalConnect();
  }

  // 计划重连（指数退避 + 抖动）
  void _scheduleReconnect() {
    if (!autoReconnect) {
      logger?.call('reconnect', 'autoReconnect disabled.');
      return;
    }

    // 如果已经计划了重连，则不重复计划（避免重入）
    if (_reconnectTimer != null) {
      logger?.call('reconnect', 'reconnect already scheduled.');
      return;
    }

    _reconnectAttempts++;
    if (maxReconnectAttempts > 0 && _reconnectAttempts > maxReconnectAttempts) {
      // 超过最大重连次数，停止重连并发出事件
      if (!_inboundController.isClosed) {
        // 重连失败
        _inboundController.add(
          IMEvent(
            IMEventType.reconnectFailed,
            data: {'attempts': _reconnectAttempts},
          ),
        );
      }
      logger?.call(
        'reconnect',
        'reconnect failed, attempts=$_reconnectAttempts',
      );
      return;
    }

    // 计算指数退避： reconnectInitialDelay * 2^(attempts-1), 上限 reconnectMaxDelay
    final baseMs =
        reconnectInitialDelay.inMilliseconds * pow(2, _reconnectAttempts - 1);
    final capped = min(baseMs, reconnectMaxDelay.inMilliseconds);
    final jitter = Random().nextInt(1000); // 0-999 ms 随机抖动
    final delayMs = capped + jitter;

    _reconnectTimer = Timer(
      Duration(milliseconds: int.parse(delayMs.toString())),
      () async {
        _reconnectTimer = null;
        // 发起连接尝试
        await _internalConnect();
      },
    );

    if (!_inboundController.isClosed) {
      // 重连计划
      _inboundController.add(
        IMEvent(
          IMEventType.reconnectScheduled,
          data: {'attempt': _reconnectAttempts, 'delayMs': delayMs},
        ),
      );
    }
    logger?.call(
      'reconnect',
      'scheduled attempt=$_reconnectAttempts delayMs=$delayMs',
    );
  }

  // 取消已经计划好的重连任务（并视为重置尝试计数）
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }
}
