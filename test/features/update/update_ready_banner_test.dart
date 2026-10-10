import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/update/presentation/widgets/update_ready_banner.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

class _ReadyController extends UpdateDownloadController {
  @override
  UpdateDownloadState build() => const UpdateDownloadState(
    phase: UpdateDownloadPhase.ready,
    version: '2026.10.10',
    filePath: '/update.apk',
  );
}

void main() {
  setUpAll(() async {
    for (final family in ['JetBrainsMono', 'NotoSansSC']) {
      await (FontLoader(family)..addFont(
            Future.value(
              ByteData.sublistView(
                File('assets/fonts/$family[wght].ttf').readAsBytesSync(),
              ),
            ),
          ))
          .load();
    }
  });
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('日语通知 $width $brightness 大字体布局和上滑关闭', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();
        final container = ProviderContainer(
          overrides: [
            updateDownloadControllerProvider.overrideWith(_ReadyController.new),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: EasyLocalization(
              supportedLocales: const [Locale('ja')],
              startLocale: const Locale('ja'),
              path: 'assets/i18n',
              assetLoader: const _Loader(),
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  theme: AppTheme.getThemeByModeAndAccent(
                    brightness: brightness,
                    accentIndex: 0,
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.8)),
                    child: child!,
                  ),
                  home: const Scaffold(body: UpdateReadyBanner()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
        final card = tester.getRect(find.byType(UpdateReadyCard));
        final action = tester.getRect(find.byType(FilledButton));
        expect(card.width, lessThanOrEqualTo(560));
        expect(action.left, greaterThanOrEqualTo(card.left));
        expect(action.right, lessThanOrEqualTo(card.right));
        await tester.fling(
          find.byType(UpdateReadyCard),
          const Offset(0, -500),
          1500,
        );
        await tester.pumpAndSettle();
        expect(
          container.read(updateDownloadControllerProvider).bannerDismissed,
          isTrue,
        );
        expect(find.byType(UpdateReadyCard), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
