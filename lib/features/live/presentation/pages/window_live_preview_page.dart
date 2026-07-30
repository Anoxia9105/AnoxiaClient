import 'dart:convert';

import 'package:anoxia/features/live/presentation/pages/live_preview_page.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 独立窗口直播预览页面
///
/// 桌面端独立窗口中的直播开播预览页面，先显示直播预览配置界面，
/// 开播后切换到 LiveRoomPage 进行直播。

/// 独立窗口直播预览页面组件
///
/// 桌面端主播开播的入口页面，先展示预览配置，再进入直播房间。
class WindowLivePreviewPage extends StatefulWidget {
  /// 窗口控制器
  final WindowController controller;

  const WindowLivePreviewPage({super.key, required this.controller});

  @override
  State<WindowLivePreviewPage> createState() => _WindowLivePreviewPageState();
}

/// 预览页面状态
///
/// 管理开播预览和直播房间的切换，处理开播请求。
class _WindowLivePreviewPageState extends State<WindowLivePreviewPage>
    with WindowListener {
  /// 直播房间数据
  _LiveRoomWindowData? _room;

  /// 屏幕共享源 ID
  String? _screenSourceId;

  /// 初始标题
  String _initialTitle = '';

  /// 初始可见性
  LiveVisibility _initialVisibility = LiveVisibility.public;

  /// 初始直播来源
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

  /// 开始直播
  ///
  /// 向服务端发起开播请求，创建直播房间。
  /// [title] 直播标题。
  /// [visibility] 直播可见性。
  /// [source] 直播来源。
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

/// 直播房间窗口数据
///
/// 存储直播房间的基本信息，用于窗口间传递。
class _LiveRoomWindowData {
  /// 房间 ID
  final String roomId;

  /// 房间标题
  final String title;

  /// 直播可见性
  final LiveVisibility visibility;

  /// 直播来源
  final LiveSource source;

  const _LiveRoomWindowData({
    required this.roomId,
    required this.title,
    required this.visibility,
    required this.source,
  });
}
