import 'dart:convert';

import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowLivePage extends StatefulWidget {
  final WindowController controller;

  const WindowLivePage({super.key, required this.controller});

  @override
  State<WindowLivePage> createState() => _WindowLivePageState();
}

class _WindowLivePageState extends State<WindowLivePage> with WindowListener {
  String _roomId = '';
  String _title = '';
  bool _isHost = false;
  LiveVisibility _visibility = LiveVisibility.public;
  LiveSource _source = LiveSource.camera;
  String? _screenSourceId;

  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);

    final args = jsonDecode(widget.controller.arguments);
    _roomId = args['roomId']?.toString() ?? '';
    _title = args['title']?.toString() ?? '';
    _isHost = args['isHost'] == true;
    _visibility = args['visibility']?.toString() == 'PRIVATE'
        ? LiveVisibility.private
        : LiveVisibility.public;
    _source = args['source']?.toString() == 'SCREEN'
        ? LiveSource.screen
        : LiveSource.camera;
    _screenSourceId = args['screenSourceId']?.toString();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title.isEmpty ? '直播' : _title,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _roomId.isEmpty
          ? const Scaffold(body: Center(child: Text('直播窗口参数错误：缺少房间号')))
          : LiveRoomPage(
              roomId: _roomId,
              title: _title,
              isHost: _isHost,
              visibility: _visibility,
              source: _source,
              screenSourceId: _screenSourceId,
            ),
    );
  }
}
