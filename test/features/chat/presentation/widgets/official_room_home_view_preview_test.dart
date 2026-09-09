// 官方引导页视觉验证（golden 预览测试，非回归断言）。
//
// 以假 Provider 渲染 OfficialRoomHomeView，将亮色 / 暗色两种主题下的
// 页面截图写入 build/official_room_preview/，供开发期肉眼核对
// 3D 胶囊导航坞的视觉效果。不生成 golden 断言文件，不进入常规回归。
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:anoxia/features/chat/presentation/widgets/official_room_home_view.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 假 WS 状态：离线，避免测试环境发起真实连接。
class _FakeWsController extends WsController {
  _FakeWsController();

  @override
  WsState build() => WsState(status: WsStatus.disconnected);
}

void main() {
  const outDir = 'build/official_room_preview';
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Directory(outDir).createSync(recursive: true);
    // easy_localization 在测试环境需手动初始化设备语言。
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalizationController.initEasyLocation();
  });

  Future<void> pumpAndCapture(
    WidgetTester tester, {
    required Brightness brightness,
    required int accentIndex,
    required String fileName,
  }) async {
    // 假更新信息：不弹更新横幅，聚焦导航坞本身。
    final overrides = [
      wsControllerProvider.overrideWith(() => _FakeWsController()),
      // 屏蔽真实 connectivity 插件（测试环境无平台通道实现）。
      networkStatusProvider.overrideWith((ref) => const Stream.empty()),
      appVersionProvider.overrideWith((ref) async => '1.2.3'),
      appUpdateCheckerProvider.overrideWith(() => _FakeUpdateChecker()),
      settingsPageControllerProvider.overrideWith(() => _FakeSettingsPage()),
    ];

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        // 与 main.dart 一致：显式指定起始语言，避免测试环境设备
        // locale（如 zh-CN）命中不存在的 zh-CN.json。
        startLocale: const Locale('zh'),
        child: ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: AppTheme.getThemeByModeAndAccent(
              brightness: brightness,
              accentIndex: accentIndex,
            ),
            home: const Scaffold(
              body: RepaintBoundary(
                key: ValueKey('preview_capture'),
                child: OfficialRoomHomeView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 直接从渲染树截图写入 PNG：预览图永远重新生成，不依赖
    // --update-goldens，也不会因缺少 golden 文件而失败。
    await binding.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview_capture')),
      );
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      File('${Directory(outDir).absolute.path}/$fileName.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('capture light theme previews', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1000);
    addTearDown(tester.view.reset);

    await pumpAndCapture(
      tester,
      brightness: Brightness.light,
      accentIndex: 0,
      fileName: 'light_top',
    );
  });

  testWidgets('capture dark theme previews', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1000);
    addTearDown(tester.view.reset);

    await pumpAndCapture(
      tester,
      brightness: Brightness.dark,
      accentIndex: 0,
      fileName: 'dark_top',
    );
  });
}

/// 假更新检查器：不发起真实网络检查。
class _FakeUpdateChecker extends AppUpdateCheckerNotifier {
  @override
  AppUpdateInfo? build() => null;
}

/// 假设置页控制器：所有动作返回默认结果。
class _FakeSettingsPage extends SettingsPageController {
  @override
  SettingsPageState build() => const SettingsPageState();
}
