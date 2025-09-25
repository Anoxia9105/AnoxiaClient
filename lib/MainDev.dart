import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notepadclient/Flavor.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/di/injector.dart' as injector;

/// DEV 环境
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  13:16
void main() async {
  //框架初始化
  WidgetsFlutterBinding.ensureInitialized();
  //语言初始化
  await EasyLocalization.ensureInitialized();

  // 配置 Flavor
  FlavorConfig.init(
    flavor: Flavor.dev,
    values: FlavorValues(
      appName: 'MyApp Dev',
      baseUrl: 'http://localhost:8080',
      wsBaseUrl: 'ws://localhost:8081',
      debug: false,
    ),
  );
  //初始化 SP
  await SPUtil.init();
  //初始化 DI
  await injector.init();


  if (DeviceUtil.isDesktop) {
    ///Windows平台
    await windowManager.ensureInitialized();

    ///窗体设置
    WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      windowManager.setHasShadow(true);
    });
  }

  print('''
 _______
< DEV >
 -------
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
  ''');

  String path = DeviceUtil.isWeb ? 'i18n' : 'assets/i18n';

  var app = ScreenUtilInit(
    designSize: Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: path,
        fallbackLocale: Locale('en', 'US'),
        saveLocale: true,
        child: App(),
      );
    },
  );

  runApp(app);
}
