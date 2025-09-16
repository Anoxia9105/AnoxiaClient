/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  13:16
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injector.dart' as injector;
import 'flavor.dart';

/// PROD 环境
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  13:16
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  FlavorConfig.init(
    flavor: Flavor.prod,
    values: FlavorValues(
      appName: 'MyApp Dev',
      baseUrl: 'https://api-dev.example.com',
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
