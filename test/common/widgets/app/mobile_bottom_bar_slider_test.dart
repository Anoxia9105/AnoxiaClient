import 'package:anoxia/common/widgets/app/mobile_bottom_bar.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 滑块全程必须收在玻璃外框内（允许 0.5px 浮点误差）。
void _expectSliderInsideBar(WidgetTester tester) {
  final bar = tester.getRect(find.byKey(const Key('mobile-bottom-bar')));
  final slider =
      tester.getRect(find.byKey(const Key('mobile-bottom-bar-slider')));
  expect(slider.left, greaterThanOrEqualTo(bar.left - 0.5),
      reason: '滑块左沿超出玻璃外框：$slider vs $bar');
  expect(slider.right, lessThanOrEqualTo(bar.right + 0.5),
      reason: '滑块右沿超出玻璃外框：$slider vs $bar');
}

Future<void> _pumpBar(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  // HapticFeedback 走 platform 通道，测试里 mock 掉避免 MissingPluginException。
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      useFallbackTranslations: true,
      // 注意：不要像正式入口那样给 MaterialApp 接 locale/delegates，
      // 测试 asset 取不到翻译会导致整树 blank；.tr() 回退 key 不影响几何断言。
      child: ProviderScope(
        overrides: [
          totalUnreadCountProvider.overrideWith((ref) => 12),
          pendingRequestCountProvider.overrideWith((ref) => 3),
        ],
        child: MaterialApp(
          theme: AppTheme.getThemeByModeAndAccent(
            brightness: Brightness.light,
            accentIndex: 0,
          ),
          home: const Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: MobileBottomBar(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 逐帧推进滑块动画，每帧都断言不超出外框。
Future<void> _pumpFramesAndCheck(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    _expectSliderInsideBar(tester);
  }
  await tester.pumpAndSettle();
  _expectSliderInsideBar(tester);
}

void main() {
  group('底部导航滑块不超出玻璃外框', () {
    testWidgets('切到 我的（最长右行行程）', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(tester);
      // 不依赖 .tr() 文案是否加载：4 个 InkWell 依次是 聊天/人员/收藏/我的。
      // 不依赖 .tr() 文案是否加载：4 个 InkWell 依次是 聊天/人员/收藏/我的。
      await tester.tap(find.byType(InkWell).last);
      await _pumpFramesAndCheck(tester);
    });

    testWidgets('从 我的 切回 聊天（最长左行行程）', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(tester);
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await _pumpFramesAndCheck(tester);
    });
  });
}
