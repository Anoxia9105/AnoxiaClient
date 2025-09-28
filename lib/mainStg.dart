import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injector.dart' as injector;
import 'flavor.dart';

/// STG 环境
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  13:16
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 配置 Flavor
  FlavorConfig.init(
    flavor: Flavor.stg,
    values: FlavorValues(
      appName: 'MyApp Stg',
      baseUrl: 'http://127.0.0.1:8080',
      wsBaseUrl: 'ws://127.0.0.1:8081',
      debug: false,
    ),
  );

  await injector.init(); // 初始化 DI

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'),Locale('ja'),],
      path: 'i18n',
      fallbackLocale: Locale('en', 'US'),
      saveLocale: true,
      child: App(),
    ),
  );
}
