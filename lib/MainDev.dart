import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notepadclient/Flavor.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'app.dart';
import 'core/di/injector.dart' as injector;

// 桌面端才需要 window_manager，所以加上条件导入
// ignore: avoid_web_libraries_in_flutter
import 'package:window_manager/window_manager.dart' as desktop;

import 'core/network/TokenManager.dart' show TokenManager;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  await SPUtil.init();
  await injector.init();
  // 预加载并缓存 token，避免后续多处并发读取
  final token = await TokenManager.instance.getToken();
  print('启动预加载的 token: $token');

  // 仅桌面端执行 window_manager 初始化
  if (DeviceUtil.isRealDesktop()) {
    await desktop.windowManager.ensureInitialized();

    const windowOptions = desktop.WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: desktop.TitleBarStyle.hidden,
    );

    desktop.windowManager.waitUntilReadyToShow(windowOptions, () async {
      await desktop.windowManager.show();
      await desktop.windowManager.focus();
      await desktop.windowManager.setHasShadow(true);
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
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: path,
        fallbackLocale: const Locale('en', 'US'),
        saveLocale: true,
        child: const App(),
      );
    },
  );

  runApp(app);
}
