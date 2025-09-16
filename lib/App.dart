import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/features/layout/MainLayoutPage.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/features/setting/presentation/controller/SettingsController.dart';
import 'package:notepadclient/shared/theme/AppTheme.dart';
import 'package:provider/provider.dart';

import 'Flavor.dart';
import 'features/auth/presentation/pages/LoginPage.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    FlavorValues values = FlavorConfig.value;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LayoutController>(
          create: (ctx) => getIt<LayoutController>(),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (ctx) => getIt<SettingsController>(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (
          BuildContext context,
          SettingsController setting,
          Widget? child,
        ) {
          setting.loadSettings();
          return MaterialApp(
            title: values.appName,
            theme: setting.theme,
            debugShowCheckedModeBanner: values.debug,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: MainLayoutPage(),
            // 这里可以配置路由表、localizationsDelegates 等
          );
        },
      ),
    );
  }
}
