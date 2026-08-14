import 'dart:convert';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

/// 独立窗口直播页面
///
/// 桌面端独立窗口中的直播房间页面，解析窗口参数后嵌入
/// [LiveRoomPage] 组件，支持主播和观众两种角色。

/// 独立窗口直播页面组件
///
/// 作为桌面端独立窗口的入口，负责解析窗口参数并初始化直播房间。
class WindowLivePage extends StatefulWidget {
  /// 窗口控制器
  final WindowController controller;

  const WindowLivePage({super.key, required this.controller});

  @override
  State<WindowLivePage> createState() => _WindowLivePageState();
}

/// 直播页面状态
///
/// 从窗口参数中解析房间信息并传递给 LiveRoomPage。
class _WindowLivePageState extends State<WindowLivePage> with WindowListener {
  /// 房间 ID
  String _roomId = '';

  /// 房间标题
  String _title = '';

  /// 是否为主播
  bool _isHost = false;

  /// 直播可见性
  LiveVisibility _visibility = LiveVisibility.public;

  /// 直播来源
  LiveSource _source = LiveSource.camera;

  /// 屏幕共享源 ID
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
      scaffoldMessengerKey: Toast.messengerKey,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _roomId.isEmpty
          ? Scaffold(
              body: Center(
                child: Text('live_window_params_missing_room_id'.tr()),
              ),
            )
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
