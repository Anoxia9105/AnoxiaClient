import 'package:anoxia/features/update/presentation/pages/update_page.dart';
import 'package:anoxia/features/update/presentation/widgets/update_sections.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/design_test_app.dart';

const _info = AppUpdateInfo(
  hasUpdate: true,
  latestVersion: '2.5.3',
  currentVersion: '2.5.2',
  downloadUrl: 'https://www.anoxia.cn/update.apk',
  releaseNotes: '修复下载中断\n优化关于与支持页面',
  fileSize: 128 * 1024 * 1024,
);

class _Download extends UpdateDownloadController {
  _Download(this.initial);
  final UpdateDownloadPhase initial;
  int installs = 0;
  @override
  UpdateDownloadState build() => UpdateDownloadState(
    phase: initial,
    version: _info.latestVersion,
    url: _info.downloadUrl,
    progress: initial == UpdateDownloadPhase.ready ? 1 : .48,
    receivedBytes: initial == UpdateDownloadPhase.ready
        ? _info.fileSize
        : 61440,
    totalBytes: _info.fileSize,
    errorMessage: initial == UpdateDownloadPhase.failed
        ? 'update_error_generic_safe'
        : '',
  );
  @override
  Future<bool> installReadyUpdate() async {
    installs++;
    return true;
  }
}

void main() {
  setUpAll(loadDesignFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  for (final width in [320.0, 390.0, 1024.0]) {
    for (final language in ['zh', 'en', 'ja']) {
      for (final phase in UpdateDownloadPhase.values) {
        testWidgets('更新页 $width $language $phase 无溢出且主操作正确', (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          try {
            await EasyLocalization.ensureInitialized();
            tester.view.physicalSize = Size(width, 1100);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final controller = _Download(phase);
            final container = ProviderContainer(
              overrides: [
                updateDownloadControllerProvider.overrideWith(() => controller),
                appVersionProvider.overrideWith((ref) async => '2.5.2+57'),
              ],
            );
            addTearDown(container.dispose);
            final captureKey = GlobalKey();
            final brightness = width == 390
                ? Brightness.dark
                : Brightness.light;
            await tester.pumpWidget(
              designTestApp(
                container: container,
                locale: Locale(language),
                brightness: brightness,
                captureKey: captureKey,
                child: const UpdatePage(updateInfo: _info),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final primary = find.byKey(const Key('update-primary-action'));
            expect(primary, findsOneWidget);
            if (phase == UpdateDownloadPhase.downloading) {
              expect(find.text('update_pause_download'.tr()), findsOneWidget);
              await tester.ensureVisible(primary);
              await tester.tap(primary);
              await tester.pump();
              expect(
                container.read(updateDownloadControllerProvider).phase,
                UpdateDownloadPhase.paused,
              );
              expect(find.text('update_resume_download'.tr()), findsOneWidget);
              await tester.tap(primary);
              await tester.pump();
              expect(
                container.read(updateDownloadControllerProvider).phase,
                UpdateDownloadPhase.downloading,
              );
            }
            if (phase == UpdateDownloadPhase.ready) {
              await tester.ensureVisible(primary);
              await tester.tap(primary);
              await tester.pumpAndSettle();
              expect(controller.installs, 0);
              await tester.tap(find.text('update_install_continue'.tr()));
              await tester.pumpAndSettle();
              expect(controller.installs, 1);
            }
            if (phase == UpdateDownloadPhase.paused) {
              expect(find.text('update_resume_download'.tr()), findsOneWidget);
            }
            if (phase == UpdateDownloadPhase.failed) {
              expect(find.text('update_retry_download'.tr()), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            if (language == 'zh' && phase == UpdateDownloadPhase.downloading) {
              await captureDesign(
                tester,
                captureKey,
                'update-${width.toInt()}-${brightness.name}',
              );
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
  testWidgets('未知大小时下载显示不定进度，暂停后停止动画且只保留一个按钮', (tester) async {
    await EasyLocalization.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final paused in [false, true]) {
      await tester.pumpWidget(
        designTestApp(
          container: container,
          locale: const Locale('zh'),
          brightness: Brightness.light,
          child: Scaffold(
            body: UpdateActionArea(
              isDownloading: !paused,
              isPaused: paused,
              hasStarted: true,
              openedInBrowser: false,
              downloadFinished: false,
              progress: 0,
              onStartDownload: () {},
              onPause: () {},
              onResume: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('update-download-progress')),
      );
      expect(indicator.value, paused ? 0 : isNull);
      expect(find.byKey(const Key('update-primary-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
