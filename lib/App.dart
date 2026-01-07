import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/provider/theme/theme_controller.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';
import 'package:notepadclient/shared/widgets/Application.dart';

import 'framework/provider/router/router.dart';



class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(appThemeProvider);
    return MaterialApp.router(
      title: 'Fluent UI Demo',
      routerConfig: router,
      theme: theme,
      builder: BotToastInit(),
      // navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
