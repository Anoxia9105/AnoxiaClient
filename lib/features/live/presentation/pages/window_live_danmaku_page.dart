import 'dart:convert';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:window_manager/window_manager.dart';

class WindowLiveDanmakuPage extends StatefulWidget {
  final WindowController controller;

  const WindowLiveDanmakuPage({super.key, required this.controller});

  @override
  State<WindowLiveDanmakuPage> createState() => _WindowLiveDanmakuPageState();
}

class _WindowLiveDanmakuPageState extends State<WindowLiveDanmakuPage>
    with WindowListener {
  static const _danmakuTopic = 'live-danmaku';

  final TextEditingController _controller = TextEditingController();
  final List<_DanmakuMessage> _messages = [];

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  String _roomId = '';
  String _title = '';
  String _clientId = '';
  Map<String, dynamic>? _anchorBounds;
  bool _loading = true;
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
      Toast.showNotificationNow('弹幕解析失败：$e');
    }
  }

  void _addMessage(_DanmakuMessage message) {
    if (message.text.trim().isEmpty) return;
    setState(() => _messages.add(message));
  }

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
      Toast.showNotificationNow('弹幕发送失败：$e');
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
              tooltip: '重连',
              onPressed: _loading ? null : _connect,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

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
              Text('弹幕窗口连接失败：$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _connect, child: const Text('重试')),
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
                    decoration: const InputDecoration(
                      hintText: '发送主播弹幕...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('发送'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DanmakuMessage {
  final String name;
  final String text;
  final bool isHost;

  const _DanmakuMessage({
    required this.name,
    required this.text,
    required this.isHost,
  });
}
