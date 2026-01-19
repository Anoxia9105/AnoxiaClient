import 'package:anoxia/pages/AppScaffold.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../common/utils/DeviceUtil.dart';
import '../framework/provider/layout/layout_controller.dart';
import '../framework/provider/theme/theme_controller.dart';

const _channel = WindowMethodChannel('example_video_player_window');


class SubWindowPage extends ConsumerStatefulWidget {
  final WindowController controller;

  const SubWindowPage({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<SubWindowPage> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isRealDesktop()) {
      windowManager.addListener(this);
    }
    _channel.setMethodCallHandler((call) async {
      print('收到方法调用: ${call.method} with arguments: ${call.arguments}');
      return '子窗口返回';
    });
    // _channel.invokeMethod('ready');
  }

  @override
  void dispose() {
    if (DeviceUtil.isRealDesktop()) {
      windowManager.removeListener(this);
    }
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    ref.read(layoutControllerProvider.notifier).toggleExtended();
  }

  @override
  void onWindowUnmaximize() {
    ref.read(layoutControllerProvider.notifier).toggleExtended();
  }

  @override
  Widget build(BuildContext context) {

    print("---->>>>>>>${widget.controller.arguments}");
    final locale = context.locale;
    return MaterialApp(
      title: '记事本客户端',
      theme: ref.watch(appThemeProvider),
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: locale,
      home: AppScaffold(body: Column(children: [
        IconButton(
          onPressed: () async {
            final result = await _channel.invokeMethod('play');
            print('main结果: $result');
          },
          icon: Icon(Icons.send),
        ),
      ],)),
    );
  }
}





