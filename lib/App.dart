import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/features/auth/presentation/pages/LoginPage.dart';
import 'package:notepadclient/features/layout/MainLayoutPage.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/features/setting/presentation/controller/SettingsController.dart';
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
            // home: LoginPage(),
            home: MainLayoutPage(),
          );
        },
      ),
    );
  }
}
