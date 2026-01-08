import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/constants/API.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../../protocol/IPacket.dart';
import '../../protocol/PacketFrame.dart';
import '../../protocol/PacketType.dart';
import '../../protocol/register/PacketRegistry.dart';
import '../auth/auth_state_provider.dart';
import 'ws_state.dart'; // 导入上面的状态

part 'ws_controller.g.dart'; // 生成文件的名字

// 使用 keepAlive: true 确保切换页面时连接不会断开
@Riverpod(keepAlive: true)
class WsController extends _$WsController {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  //记录重试次数
  int _reconnectAttempts = 0;

  // 用于分发消息的 StreamController
  final _messageController = StreamController<PacketFrame<IPacket>>.broadcast();

  @override
  WsState build() {
    //监听认证状态
    final auth = ref.watch(authStateProvider);
    //使用 Future.microtask 确保在 build 完成后再执行初始化
    if (auth.status == AuthStatus.authenticated) {
      Future.microtask(() => _initConnection());
    } else {
      _disposeAll();
    }

    // 自动清理资源
    ref.onDispose(() {
      _disposeAll();
    });
    return WsState(status: WsStatus.disconnected);
  }

  /// 内部引导连接的方法（处理异步获取 Token）
  void _initConnection() async {
    // 加上保护，避免同时启动多个连接
    if (state.status == WsStatus.connecting ||
        state.status == WsStatus.connected)
      return;

    final token = await TokenManager.instance.getToken();
    if (token != null && token.isNotEmpty) {
      connect(token);
    }
  }

  /// 暴露给外部的消息流
  Stream<dynamic> get messageStream => _messageController.stream;

  /// 连接方法
  Future<void> connect(String token) async {
    // 已连接则不重复连接
    if (state.status == WsStatus.connected) return;

    // 更新状态为连接中
    state = WsState(status: WsStatus.connecting);

    // 建立连接
    try {
      String url = API.wsBaseUrl + token;
      _channel = WebSocketChannel.connect(Uri.parse(url));
      //等待真正的握手成功
      await _channel!.ready;

      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message),
        onError: (err) => _handleError(err),
        onDone: () => _handleDone(),
        cancelOnError: true,
      );

      //连接成功，重置重试次数
      _reconnectAttempts = 0;
      state = WsState(status: WsStatus.connected);
      log.info("ws连接成功【重置重试次数】,$_reconnectAttempts");
      //启动心跳机制
      _startHeartbeat();
    } catch (e) {
      _handleError(e);
    }
  }

  /// 发送消息
  void sendMessage(dynamic msg) {
    log.info("ws发送消息: $msg");
    if (state.status != WsStatus.connected) return;
    _channel?.sink.add(msg is Map ? jsonEncode(msg) : msg);
  }

  /// 内部处理：收到消息
  void _handleIncomingMessage(dynamic message) {
    log.info("WS收到消息: $message");
    if (message == 'pong') return; // 拦截心跳响应

    try {
      // 2. 将原始字符串解析为 Map
      final Map<String, dynamic> jsonMap = jsonDecode(message as String);

      // 3. 提取 topic 并识别 PacketType (利用之前写的 from 方法，兼容数字/字符串)
      final topic = PacketType.from(jsonMap['topic']);
      final rawData = jsonMap['data'] as Map<String, dynamic>?;

      if (rawData == null) {
        log.warning("收到空数据包: $topic");
        return;
      }

      // 4. 💡 核心步骤：通过注册表解析具体的 IPacket 子类
      final packetData = PacketRegistry.parse(topic, rawData);

      if (packetData != null) {
        // 5. 封装成 Frame 放入流中
        final frame = PacketFrame(topic: topic, data: packetData);
        _messageController.add(frame);

        log.info("WS 解析并分发成功: ${topic.name}");
      } else {
        log.warning("未注册的协议主题或解析失败: $topic");
      }
    } catch (e, stack) {
      log.error("WS 消息处理异常: $e", stack);
    }
  }

  /// 内部处理：心跳机制
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      sendMessage('ping');
    });
  }

  /// 内部处理：错误与重连
  void _handleError(dynamic err) {
    state = WsState(status: WsStatus.error, error: err.toString());
    _retryConnection();
  }

  /// 内部处理：连接关闭与重连
  void _handleDone() {
    state = WsState(status: WsStatus.disconnected);
    _retryConnection();
  }

  // 内部处理：重连逻辑
  void _retryConnection() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    // 指数退避算法计算延迟：2, 4, 8, 16, 最后固定在 30s
    int delaySeconds = (1 << _reconnectAttempts).clamp(2, 30);
    log.warning("连接已断开，将在 $delaySeconds 秒后进行第 $_reconnectAttempts 次重连尝试...");

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      final token = await TokenManager.instance.getToken();

      _reconnectAttempts++;
      if (token != null) {
        log.info("开始执行重连...");
        connect(token);
      } else {
        log.error("重连失败：找不到 Token");
        // 如果没有 token，可能需要跳转到登录页或重新获取
      }
    });
  }

  void _disposeAll() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}

//消息事件总线 所有消息都会通过这个流分发出去
@riverpod
Stream<PacketFrame<IPacket>> wsMessageStream(Ref ref) {
  final controller = ref.watch(wsControllerProvider.notifier);
  // 这里我们直接强转，因为 _messageController 内部就是这个类型
  return controller.messageStream.cast<PacketFrame<IPacket>>();
}
