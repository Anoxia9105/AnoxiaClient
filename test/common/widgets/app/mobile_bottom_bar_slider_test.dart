import 'package:anoxia/common/widgets/app/mobile_bottom_bar.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  int accentIndex = 0,
}) async {
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
      // 测试 asset 取不到翻译会导致整树 blank；.tr() 回退 key 不影响断言。
      child: ProviderScope(
        overrides: [
          totalUnreadCountProvider.overrideWith((ref) => 12),
          pendingRequestCountProvider.overrideWith((ref) => 3),
        ],
        child: MaterialApp(
          theme: AppTheme.getThemeByModeAndAccent(
            brightness: brightness,
            accentIndex: accentIndex,
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

void main() {
  group('平面贴底底部导航', () {
    testWidgets('无滑块无胶囊：贴底平面 + 顶部细线分隔', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(tester);

      // 旧版弹簧滑块已删除。
      expect(
        find.byKey(const Key('mobile-bottom-bar-slider')),
        findsNothing,
      );

      final barFinder = find.byKey(const Key('mobile-bottom-bar'));
      expect(barFinder, findsOneWidget);
      final container = tester.widget<Container>(barFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      // 平面：无圆角、无阴影。
      expect(decoration!.borderRadius, isNull);
      expect(decoration.boxShadow, isNull);
      // 顶部细线分隔内容区。
      expect(decoration.border?.top, isNotNull);

      // 贴底：底栏底边与屏幕底边对齐（允许 SafeArea 1px 误差）。
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final barRect = tester.getRect(barFinder);
      expect(barRect.bottom, closeTo(screenHeight, 1.0));
    });

    testWidgets('选中只加粗：图标描粗 + 文字 w700 + 主题主色', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(tester);
      final context = tester.element(find.byType(Scaffold));
      final primary = Theme.of(context).colorScheme.primary;

      // 默认选中第一项（聊天）。
      final icons = tester.widgetList<HugeIcon>(find.byType(HugeIcon)).toList();
      expect(icons.length, 4);
      expect(icons.first.strokeWidth, 2.4);
      expect(icons.first.color, primary);
      for (final icon in icons.skip(1)) {
        expect(icon.strokeWidth, 1.6);
        expect(icon.color, isNot(primary));
      }

      // 不依赖 .tr() 文案是否加载：取底栏内 11px 导航文字依次断言样式。
      final labelStyles = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('mobile-bottom-bar')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.style)
          .where((s) => s?.fontSize == 11)
          .toList();
      expect(labelStyles.length, 4);
      expect(labelStyles.first?.fontWeight, FontWeight.w700);
      expect(labelStyles.first?.color, primary);
      for (final style in labelStyles.skip(1)) {
        expect(style?.fontWeight, FontWeight.w400);
        expect(style?.color, isNot(primary));
      }
    });

    testWidgets('点击切换选中项', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(tester);
      // 不依赖 .tr() 文案是否加载：4 个 InkWell 依次是 聊天/人员/收藏/我的。
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final primary = Theme.of(context).colorScheme.primary;
      final icons = tester.widgetList<HugeIcon>(find.byType(HugeIcon)).toList();
      expect(icons.last.strokeWidth, 2.4);
      expect(icons.last.color, primary);
      expect(icons.first.strokeWidth, 1.6);
    });

    testWidgets('选中色跟随主题强调色（亮/暗 + 换色）', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await _pumpBar(
        tester,
        brightness: Brightness.dark,
        accentIndex: 5,
      );
      final context = tester.element(find.byType(Scaffold));
      final primary = Theme.of(context).colorScheme.primary;
      final icons = tester.widgetList<HugeIcon>(find.byType(HugeIcon)).toList();
      expect(icons.first.color, primary);
      final labelStyles = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('mobile-bottom-bar')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.style)
          .where((s) => s?.fontSize == 11)
          .toList();
      expect(labelStyles.length, 4);
      expect(labelStyles.first?.color, primary);
      expect(labelStyles.first?.fontWeight, FontWeight.w700);
    });
  });
}
