import 'package:anoxia/features/update/presentation/pages/update_page.dart';
import 'package:anoxia/features/update/presentation/widgets/update_sections.dart';
import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('独立强制更新页在没有 GoRouter 时正常渲染', (tester) async {
    final exitCalls = <MethodCall>[];
    const navigation = MethodChannel('app_navigation');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(navigation, (
      call,
    ) async {
      exitCalls.add(call);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        navigation,
        null,
      ),
    );
    SharedPreferences.setMockInitialValues(const {});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await EasyLocalization.ensureInitialized();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // networkStatus 内含 checkConnectivity().timeout(3s)，
            // 真机通道在测试里不返回，用静态流代替，避免 pending timer。
            networkStatusProvider.overrideWith(
              (ref) => Stream.value(const [ConnectivityResult.wifi]),
            ),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('zh')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('zh'),
            startLocale: const Locale('zh'),
            child: const MaterialApp(
              home: UpdatePage(
                standalone: true,
                updateInfo: AppUpdateInfo(
                  hasUpdate: true,
                  latestVersion: '2.4.0',
                  currentVersion: '2.3.5',
                  downloadUrl: 'https://downloads.anoxia.cn/app.apk',
                  releaseNotes: '修复更新页渲染问题',
                  forceUpdate: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(UpdateHeroCard), findsOneWidget);
      expect(find.byType(UpdateForceBadge), findsOneWidget);
      expect(find.byType(UpdateActionArea), findsOneWidget);
      expect(find.text('修复更新页渲染问题'), findsOneWidget);
      await tester.ensureVisible(find.text('update_exit_app'.tr()));
      await tester.tap(find.text('update_exit_app'.tr()));
      await tester.pump();
      expect(exitCalls.map((call) => call.method), ['exitApp']);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
