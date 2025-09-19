import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/features/layout/MainLayoutPage.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/features/setting/controller/SettingsController.dart';
import 'package:provider/provider.dart';

import 'Flavor.dart';

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
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => getIt<AuthController>(),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (ctx) => getIt<SettingsController>(),
        ),
        ChangeNotifierProvider<ChatController>(
          create: (ctx) => getIt<ChatController>(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder:
            (BuildContext context, SettingsController setting, Widget? child) {
              setting.loadSettings();
              return MaterialApp(
                title: values.appName,
                theme: setting.theme,
                debugShowCheckedModeBanner: values.debug,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: MainLayoutPage(),
              );
            },
      ),
    );
  }
}
