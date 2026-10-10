import 'dart:convert';
import 'dart:io';

import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_theme_section.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

void main() {
  testWidgets('系统模式实时跟随亮度，手动模式保持固定，选择可恢复', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_brightness': 'dark'});
    await SPUtil.instance.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() async {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      await tester.pump(const Duration(milliseconds: 1));
    });
    expect(container.read(themeModeProvider), ThemeMode.dark);
    final subscription = container.listen(appThemeProvider, (_, _) {});
    addTearDown(subscription.close);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(appThemeProvider).brightness, Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(appThemeProvider).brightness, Brightness.dark);
    final restored = ThemeModeController();
    addTearDown(restored.dispose);
    expect(restored.state, ThemeMode.system);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(appThemeProvider).brightness, Brightness.light);
    container.read(customAccentColorProvider.notifier).setCustomColor(Colors.teal);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(appThemeProvider).brightness, Brightness.dark);
    expect(container.read(customAccentColorProvider), Colors.teal);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump(const Duration(milliseconds: 1));
    expect(container.read(appThemeProvider).brightness, Brightness.light);
    expect(container.read(customAccentColorProvider), Colors.teal);
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets('外观设置可选择跟随系统，宽度 $width 无溢出', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: const [Locale('zh')],
            path: 'assets/i18n',
            startLocale: const Locale('zh'),
            assetLoader: const _DiskLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: SettingsThemeSection(
                      onModeChanged: container
                          .read(themeModeProvider.notifier)
                          .setMode,
                      onAccentChanged: (_) {},
                      onCustomColorChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('跟随系统'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
