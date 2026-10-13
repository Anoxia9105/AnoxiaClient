import 'package:anoxia/features/app/presentation/pages/error_page.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/features/app/presentation/pages/error_page_strings.dart';
import 'package:anoxia/features/app/presentation/pages/startup_error_app.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SPUtil.instance.init();
    await SPUtil.instance.clear();
  });

  test('启动兜底三语文案与正式语言包保持一致', () {
    for (final language in ErrorPageStrings.fallback.entries) {
      final translations =
          jsonDecode(
                File('assets/i18n/${language.key}.json').readAsStringSync(),
              )
              as Map;
      for (final label in language.value.entries) {
        expect(
          translations[label.key],
          label.value,
          reason: '${language.key}/${label.key}',
        );
      }
    }
  });

  Future<void> mount(
    WidgetTester tester,
    String language, {
    Brightness brightness = Brightness.light,
    VoidCallback? onClose,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.getThemeByModeAndAccent(
          brightness: brightness,
          accentIndex: 3,
        ),
        home: ErrorPage(
          details: 'MissingPluginException: diagnostic',
          onClose: onClose,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final entry in {
    'en': 'Unable to display this page',
    'ja': 'ページを表示できません',
    'zh': '页面暂时无法显示',
  }.entries) {
    testWidgets('国际化未初始化时仍按 ${entry.key} 显示错误文案', (tester) async {
      await mount(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['zh', 'en', 'ja']) {
    testWidgets('启动失败壳读取已保存的 $language 与自定义暗色主题', (tester) async {
      await SPUtil.instance.setMulti({
        'locale': language,
        'theme_brightness': 'dark',
        StorageKeys.customAccentEnabled: true,
        StorageKeys.customAccentColor: 0xff2fa87a,
      });
      await tester.pumpWidget(const StartupErrorApp(details: 'original error'));
      await tester.pumpAndSettle();
      final title =
          ErrorPageStrings.fallback[language]!['error_page_startup_title']!;
      expect(find.text(title), findsOneWidget);
      final theme = Theme.of(tester.element(find.text(title)));
      expect(theme.brightness, Brightness.dark);
      expect(
        theme.colorScheme.primary,
        AppTheme.getThemeForCustomColor(
          brightness: Brightness.dark,
          color: const Color(0xff2fa87a),
        ).colorScheme.primary,
      );
      final shape =
          theme.filledButtonTheme.style!.shape!.resolve({})
              as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(6));
      expect(find.text('original error'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('启动错误页跟随系统亮暗切换，不依赖业务 Provider', (tester) async {
    await SPUtil.instance.set('theme_brightness', 'system');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const StartupErrorApp(details: 'error'));
    await tester.pumpAndSettle();
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(ErrorPage))).brightness;
    expect(brightness(), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小窗口与大字号下错误详情可滚动，没有布局溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, 'ja', onClose: () {});
    await tester.ensureVisible(find.text('技術的な詳細'));
    await tester.tap(find.text('技術的な詳細'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('复制保留完整原始异常，系统成功后才显示成功反馈', (tester) async {
    final gate = Completer<void>();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String;
          await gate.future;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester, 'en');
    await tester.tap(find.text('Copy error details'));
    await tester.pump();
    expect(copied, 'MissingPluginException: diagnostic');
    expect(find.text('Error details copied'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Error details copied'), findsOneWidget);
  });

  testWidgets('错误详情默认收起，复制为主题主按钮，关闭回调有效', (tester) async {
    var closed = false;
    await mount(
      tester,
      'zh',
      brightness: Brightness.dark,
      onClose: () => closed = true,
    );
    expect(find.text('MissingPluginException: diagnostic'), findsNothing);
    expect(find.widgetWithText(FilledButton, '复制错误信息'), findsOneWidget);
    final copy = tester.element(find.text('复制错误信息'));
    final theme = Theme.of(copy);
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.colorScheme.primary,
      AppTheme.getThemeByModeAndAccent(
        brightness: Brightness.dark,
        accentIndex: 3,
      ).colorScheme.primary,
    );
    await tester.tap(find.text('技术详情'));
    await tester.pumpAndSettle();
    expect(find.text('MissingPluginException: diagnostic'), findsOneWidget);
    await tester.tap(find.text('关闭窗口'));
    expect(closed, isTrue);
  });

  testWidgets('复制等待系统成功，失败显示本地化反馈且不抛异步异常', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard_denied');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester, 'en');
    await tester.tap(find.text('Copy error details'));
    await tester.pumpAndSettle();
    expect(find.text('Could not copy. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
