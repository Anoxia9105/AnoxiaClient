import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_about_support_section.dart';
import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/design_test_app.dart';

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

class _NoUpdate extends AppUpdateCheckerNotifier {
  @override
  AppUpdateInfo? build() => null;
}

void main() {
  setUpAll(loadDesignFonts);
  testWidgets('关于页明确独立开发、署名右对齐、Logo 无装饰底板', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appUpdateCheckerProvider.overrideWith(_NoUpdate.new)],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh')],
          startLocale: const Locale('zh'),
          path: 'assets/i18n',
          assetLoader: const _Loader(),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SettingsAboutSupportSection(
                    appVersionText: '2.5.2+57',
                    hasAppUpdate: false,
                    pageState: const SettingsPageState(),
                    onCheckUpdate: () {},
                    onNavigateToUpdatePage: (_) {},
                    onOpenOpenSourceLicenses: () {},
                    onOpenDeveloperTribute: () {},
                    onOpenFeedback: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('由我一个人'), findsOneWidget);
    expect(find.textContaining('很多人在帮忙'), findsNothing);
    expect(find.byKey(const Key('about-author-signature')), findsOneWidget);
    final signature = tester.widget<Align>(
      find.byKey(const Key('about-author-signature')),
    );
    expect(signature.alignment, AlignmentDirectional.centerEnd);
    expect(find.byKey(const Key('about-flat-logo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final language in ['zh', 'en', 'ja']) {
      for (final brightness in Brightness.values) {
        testWidgets('关于页 $width $language $brightness 大字体与入口可用', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          await EasyLocalization.ensureInitialized();
          tester.view.physicalSize = Size(width, 1050);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = ProviderContainer(
            overrides: [appUpdateCheckerProvider.overrideWith(_NoUpdate.new)],
          );
          addTearDown(container.dispose);
          var feedback = 0;
          var updateChecks = 0;
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            designTestApp(
              container: container,
              locale: Locale(language),
              brightness: brightness,
              captureKey: captureKey,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SettingsAboutSupportSection(
                    appVersionText: '2.5.2+57',
                    hasAppUpdate: false,
                    pageState: const SettingsPageState(),
                    onCheckUpdate: () => updateChecks++,
                    onNavigateToUpdatePage: (_) {},
                    onOpenOpenSourceLicenses: () {},
                    onOpenDeveloperTribute: () {},
                    onOpenFeedback: () => feedback++,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final updateButton = find.byKey(
            const Key('about-check-update-button'),
          );
          expect(tester.widget(updateButton), isA<FilledButton>());
          await tester.ensureVisible(updateButton);
          await tester.tap(updateButton);
          expect(updateChecks, 1);
          final action = find.byKey(const Key('about-feedback-action'));
          await tester.ensureVisible(action);
          await tester.tap(action);
          expect(feedback, 1);
          final signature = tester.widget<Align>(
            find.byKey(const Key('about-author-signature')),
          );
          expect(signature.alignment, AlignmentDirectional.centerEnd);
          if (language == 'zh' && (width == 390 || width == 1440)) {
            await captureDesign(
              tester,
              captureKey,
              'about-${width.toInt()}-${brightness.name}',
            );
          }
        });
      }
    }
  }
}
