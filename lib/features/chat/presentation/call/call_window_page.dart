import 'dart:convert';

import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/Channel.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/theme/AppColors.dart';
import 'package:anoxia/framework/theme/AppTheme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'component/deesktop/call_desktop_app_bar.dart';
import 'call_room_page.dart';

class CallWindowPage extends ConsumerStatefulWidget {
  final WindowController controller;

  const CallWindowPage({super.key, required this.controller});

  @override
  ConsumerState createState() => _CallWindowPageState();
}

class _CallWindowPageState extends ConsumerState<CallWindowPage>
    with WindowListener {
  int _themeIndex = 0;
  String _title = "";
  String _roomId = "";

  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);
    log.info("初始化通话页面,接收到参数>>>>>>${widget.controller.arguments}");

    final args = jsonDecode(widget.controller.arguments);
    _themeIndex = args['themeIndex'] ?? 0;
    _title = args["title"] ?? "";
    _roomId = args["roomId"] ?? "";
    //获取token
    ref.read(roomTokenProvider(_roomId));

    Channel.callChannel.setMethodCallHandler((call) async {
      log.info("CAll|>>> 收到数据$call");
      if (call.method == Channel.callChannelMethod) {
        final data = call.arguments as Map;
        setState(() {
          if (data.containsKey('themeIndex')) {
            _themeIndex = data['themeIndex'];
          }
          if (data.containsKey('locale')) {
            String localeCode = data['locale'];
            context.setLocale(Locale(localeCode));
          }
        });
      }
    });
  }

  @override
  Future<void> onWindowClose() async {
    // 1. 获取拦截状态
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      try {
        await Channel.callChannel.invokeMethod("on_call_window_close");
      } catch (e) {
        log.error("发送关闭消息失败", e);
      }
      await windowManager.setPreventClose(false);

      await windowManager.close();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    Channel.callChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = AppTheme.getTheme(index: _themeIndex);

    final tokenAsync = ref.watch(roomTokenProvider(_roomId));
    return MaterialApp(
      title: _title,
      theme: themeData,
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [BotToastNavigatorObserver()],
      home: Container(
        decoration: BoxDecoration(
          gradient: themeData.extension<AppColors>()?.scaffoldGradient,
        ),
        child: Scaffold(
          appBar: CallDesktopAppbar(title: _title),
          body: tokenAsync.when(
            data: (token) {
              log.info("Token 获取成功（开始启动通话）: $token");
              return CallRoomPage(token: token);
            },
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('call_window_room_creation_failed'.tr()),
                  FilledButton(
                    onPressed: () => ref.invalidate(roomTokenProvider(_roomId)),
                    child: Text('call_window_retry'.tr()),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
