import 'dart:convert';

import 'package:anoxia/features/live/presentation/pages/live_preview_page.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowLivePreviewPage extends StatefulWidget {
  final WindowController controller;

  const WindowLivePreviewPage({super.key, required this.controller});

  @override
  State<WindowLivePreviewPage> createState() => _WindowLivePreviewPageState();
}

class _WindowLivePreviewPageState extends State<WindowLivePreviewPage>
    with WindowListener {
  _LiveRoomWindowData? _room;
  String? _screenSourceId;
  String _initialTitle = '';
  LiveVisibility _initialVisibility = LiveVisibility.public;
  LiveSource _initialSource = LiveSource.camera;

  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);

    final args = jsonDecode(widget.controller.arguments);
    _initialTitle = args['title']?.toString() ?? '';
    _initialVisibility = args['visibility']?.toString() == 'PRIVATE'
        ? LiveVisibility.private
        : LiveVisibility.public;
    _initialSource = args['source']?.toString() == 'SCREEN'
        ? LiveSource.screen
        : LiveSource.camera;
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
    final room = _room;
    return MaterialApp(
      title: room == null ? '新建直播' : room.title,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: room == null
          ? LivePreviewPage(
            visibility: _initialVisibility,
            initialTitle: _initialTitle,
            initialSource: _initialSource,
              onStart:
                  ({
                    required title,
                    required visibility,
                    required source,
                    sourceId,
                  }) async {
                    final room = await _startLive(
                      title: title,
                      visibility: visibility,
                      source: source,
                    );
                    setState(() {
                      _room = room;
                      _screenSourceId = sourceId;
                    });
                  },
            )
          : LiveRoomPage(
              roomId: room.roomId,
              title: room.title,
              isHost: true,
              visibility: room.visibility,
              source: room.source,
              screenSourceId: _screenSourceId,
            ),
    );
  }

  Future<_LiveRoomWindowData> _startLive({
    required String title,
    required LiveVisibility visibility,
    required LiveSource source,
  }) async {
    final res = await DioClient().post(
      '/live/start',
      data: {
        'title': title,
        'visibility': visibility.serverValue,
        'source': source.serverValue,
      },
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '未知错误');
    }

    final data = res.data?['data'];
    if (data is! Map || data['roomId'] == null) {
      throw Exception('服务端未返回直播间信息');
    }

    return _LiveRoomWindowData(
      roomId: data['roomId'].toString(),
      title: data['title']?.toString() ?? title,
      visibility: data['visibility']?.toString() == 'PRIVATE'
          ? LiveVisibility.private
          : LiveVisibility.public,
      source: data['source']?.toString() == 'SCREEN'
          ? LiveSource.screen
          : LiveSource.camera,
    );
  }

}

class _LiveRoomWindowData {
  final String roomId;
  final String title;
  final LiveVisibility visibility;
  final LiveSource source;

  const _LiveRoomWindowData({
    required this.roomId,
    required this.title,
    required this.visibility,
    required this.source,
  });
}
