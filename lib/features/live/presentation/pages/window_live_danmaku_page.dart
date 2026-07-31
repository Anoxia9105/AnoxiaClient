import 'dart:convert';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

/// 独立窗口弹幕页面
///
/// 在桌面端独立窗口中显示直播弹幕，支持实时收发弹幕消息，
/// 自动定位到主直播窗口旁边。

/// 独立窗口弹幕页面组件
///
/// 桌面端通过独立窗口显示弹幕，连接 LiveKit 房间接收实时弹幕数据，
/// 主播可在此窗口发送弹幕。
class WindowLiveDanmakuPage extends StatefulWidget {
  /// 窗口控制器
  final WindowController controller;

  const WindowLiveDanmakuPage({super.key, required this.controller});

  @override
  State<WindowLiveDanmakuPage> createState() => _WindowLiveDanmakuPageState();
}

/// 弹幕页面状态
///
/// 管理弹幕窗口的完整生命周期，包括连接房间、接收弹幕、发送弹幕和窗口定位。
class _WindowLiveDanmakuPageState extends State<WindowLiveDanmakuPage>
    with WindowListener {
  /// 弹幕消息主题
  static const _danmakuTopic = 'live-danmaku';

  /// 弹幕输入控制器
  final TextEditingController _controller = TextEditingController();

  /// 弹幕消息列表
  final List<_DanmakuMessage> _messages = [];

  /// 房间对象
  Room? _room;

  /// 房间事件监听器
  EventsListener<RoomEvent>? _listener;

  /// 房间 ID
  String _roomId = '';

  /// 房间标题
  String _title = '';

  /// 客户端 ID
  String _clientId = '';

  /// 主窗口边界信息
  Map<String, dynamic>? _anchorBounds;

  /// 是否加载中
  bool _loading = true;

  /// 错误信息
  Object? _error;

  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);

    final args = jsonDecode(widget.controller.arguments);
    _roomId = args['roomId']?.toString() ?? '';
    _title = args['title']?.toString() ?? '';
    _clientId = args['clientId']?.toString() ?? '';
    final anchorBounds = args['anchorBounds'];
    if (anchorBounds is Map) {
      _anchorBounds = Map<String, dynamic>.from(anchorBounds);
    }
    _placeBesideLiveWindow();
    _connect();
  }

  @override
  Future<void> onWindowClose() async {
    final shouldPreventClose = await windowManager.isPreventClose();
    if (!shouldPreventClose) return;

    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _listener?.dispose();
    _controller.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  /// 连接房间
  ///
  /// 获取 LiveKit Token 并连接到直播房间，注册数据事件监听。
  Future<void> _connect() async {
    if (_roomId.isEmpty) {
      setState(() {
        _error = '缺少房间号';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _listener?.dispose();
      await _room?.disconnect();
      await _room?.dispose();

      final token = await _fetchToken(_roomId);
      final room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      await room.prepareConnection(API.wsRoomBaseUrl, token);
      await room.connect(API.wsRoomBaseUrl, token);
      final listener = room.createListener()
        ..on<DataReceivedEvent>(_handleDataEvent);

      if (!mounted) {
        await listener.dispose();
        await room.disconnect();
        await room.dispose();
        return;
      }

      setState(() {
        _room = room;
        _listener = listener;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// 定位弹幕窗口到直播窗口旁边
  ///
  /// 根据主窗口的边界信息，将弹幕窗口放置在右侧。
  Future<void> _placeBesideLiveWindow() async {
    final anchor = _anchorBounds;
    if (anchor == null) return;

    double numberValue(String key, double fallback) {
      final value = anchor[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    try {
      final right = numberValue('right', 0);
      final top = numberValue('top', 0);
      final height = numberValue('height', 720);
      await windowManager.setBounds(
        Rect.fromLTWH(right + 8, top, 360, height.clamp(420, 860).toDouble()),
      );
    } catch (_) {}
  }

  /// 获取 LiveKit Token
  ///
  /// 向服务端请求进入房间的 Token。
  /// [roomId] 房间 ID。
  Future<String> _fetchToken(String roomId) async {
    final res = await DioClient().get(
      '/live/token',
      queryParameters: {
        'roomId': roomId,
        if (_clientId.isNotEmpty) 'clientId': _clientId,
      },
    );
    if (res.data?['code'] == 200) {
      return res.data!['data'].toString();
    }
    throw Exception(
      res.data?['msg'] ?? res.data?['message'] ?? '获取直播 token 失败',
    );
  }

  /// 处理数据事件
  ///
  /// 解析弹幕主题消息并添加到消息列表。
  /// [event] 接收到的数据事件。
  void _handleDataEvent(DataReceivedEvent event) {
    if (event.topic != _danmakuTopic) return;
    try {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>? ?? json;
      _addMessage(
        _DanmakuMessage(
          name: payload['name']?.toString() ?? '观众',
          text: payload['text']?.toString() ?? '',
          isHost: payload['isHost'] == true,
        ),
      );
    } catch (e) {
      Toast.showNotificationNow('live_danmaku_parse_error'.tr(args: [e.toString()]));
    }
  }

  /// 添加弹幕消息
  ///
  /// 将非空消息添加到列表中。
  /// [message] 弹幕消息对象。
  void _addMessage(_DanmakuMessage message) {
    if (message.text.trim().isEmpty) return;
    setState(() => _messages.add(message));
  }

  /// 发送弹幕消息
  ///
  /// 通过 LiveKit 数据通道广播弹幕内容。
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final room = _room;
    final localParticipant = room?.localParticipant;
    if (localParticipant == null) return;

    final message = _DanmakuMessage(name: '主播', text: text, isHost: true);
    _addMessage(message);
    _controller.clear();

    try {
      await localParticipant.publishData(
        utf8.encode(
          jsonEncode({
            'payload': {'text': text, 'isHost': true, 'name': '主播'},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        ),
        reliable: true,
        topic: _danmakuTopic,
      );
    } catch (e) {
      Toast.showNotificationNow('live_danmaku_send_error'.tr(args: [e.toString()]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title.isEmpty ? '直播弹幕' : '弹幕 - $_title',
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title.isEmpty ? '直播弹幕' : _title),
          actions: [
            IconButton(
              tooltip: 'live_reconnect_tooltip'.tr(),
              onPressed: _loading ? null : _connect,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  /// 构建页面主体内容
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('live_danmaku_connect_failed'.tr(args: [(_error ?? '').toString()]), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _connect, child: Text('live_action_retry'.tr())),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${message.name}: ',
                        style: TextStyle(
                          color: message.isHost
                              ? Colors.redAccent
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: message.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'live_danmaku_placeholder'.tr(),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: Text('toolbar_send'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 弹幕消息数据类
class _DanmakuMessage {
  /// 发送者名称
  final String name;

  /// 消息文本
  final String text;

  /// 是否为主播消息
  final bool isHost;

  const _DanmakuMessage({
    required this.name,
    required this.text,
    required this.isHost,
  });
}
