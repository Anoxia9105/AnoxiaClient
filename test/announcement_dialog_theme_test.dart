import 'package:anoxia/features/announcement/presentation/widgets/announcement_dialog.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Announcement _announcement(AnnouncementLevel level) => Announcement(
      id: 1,
      revision: 2,
      title: '标题',
      content: '内容',
      level: level,
      publishAt: DateTime(2026, 9, 1),
      expireAt: null,
      read: false,
      acknowledged: false,
    );

Future<void> _pumpDialog(
  WidgetTester tester, {
  required ThemeData theme,
  required AnnouncementLevel level,
  Future<bool> Function()? onAcknowledge,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      useFallbackTranslations: true,
      child: MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AnnouncementDialog(
            announcement: _announcement(level),
            onClose: () {},
            onAcknowledge: onAcknowledge ?? () async => true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('系统公告弹窗主题色适配', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final accent in [0, 4, 13]) {
        testWidgets(
            '需确认公告跟随主题色 brightness=$brightness accent=$accent', (tester) async {
          final theme = AppTheme.getThemeByModeAndAccent(
            brightness: brightness,
            accentIndex: accent,
          );
          final scheme = theme.colorScheme;
          await _pumpDialog(
            tester,
            theme: theme,
            level: AnnouncementLevel.required,
          );

          // 确认按钮背景必须使用主题 primary（而非固定 warning 黄）。
          final buttonCtx =
              tester.element(find.byKey(const Key('announcement-acknowledge')));
          final button = tester.widget<FilledButton>(
            find.byKey(const Key('announcement-acknowledge')),
          );
          const states = <WidgetState>{};
          final bg = button.style?.backgroundColor?.resolve(states) ??
              Theme.of(buttonCtx)
                  .filledButtonTheme
                  .style
                  ?.backgroundColor
                  ?.resolve(states);
          expect(bg, scheme.primary);

          // 需确认徽标文字跟随 primary。
          final badge = tester.widgetList<Text>(find.byType(Text)).firstWhere(
                (t) => t.style?.color == scheme.primary,
                orElse: () => throw TestFailure('未找到 primary 色徽标'),
              );
          expect(badge.style?.fontWeight, FontWeight.w600);

          // 图标底使用 primaryContainer。
          final chips = tester
              .widgetList<Container>(find.byType(Container))
              .where((c) => c.decoration is BoxDecoration)
              .map((c) => c.decoration! as BoxDecoration)
              .where((d) => d.color == scheme.primaryContainer);
          expect(chips, isNotEmpty);
        });

        testWidgets('普通公告关闭按钮跟随主题色 brightness=$brightness accent=$accent',
            (tester) async {
          final theme = AppTheme.getThemeByModeAndAccent(
            brightness: brightness,
            accentIndex: accent,
          );
          final scheme = theme.colorScheme;
          await _pumpDialog(
            tester,
            theme: theme,
            level: AnnouncementLevel.normal,
          );
          final buttonCtx =
              tester.element(find.byKey(const Key('announcement-close')));
          final button = tester.widget<FilledButton>(
            find.byKey(const Key('announcement-close')),
          );
          const states = <WidgetState>{};
          final bg = button.style?.backgroundColor?.resolve(states) ??
              Theme.of(buttonCtx)
                  .filledButtonTheme
                  .style
                  ?.backgroundColor
                  ?.resolve(states) ??
              scheme.primary;
          expect(bg, scheme.primary);
        });
      }
    }

    testWidgets('错误条使用 onErrorContainer 保证深浅色可读', (tester) async {
      final theme = AppTheme.getThemeByModeAndAccent(
        brightness: Brightness.light,
        accentIndex: 0,
      );
      await _pumpDialog(
        tester,
        theme: theme,
        level: AnnouncementLevel.required,
        onAcknowledge: () async => false,
      );
      await tester.tap(find.byKey(const Key('announcement-acknowledge')));
      await tester.pumpAndSettle();
      final error = tester.widget<Text>(
        find.byKey(const Key('announcement-ack-error')),
      );
      expect(error.style?.color, theme.colorScheme.onErrorContainer);
    });
  });
}
