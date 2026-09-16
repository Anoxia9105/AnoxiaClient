import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

/// 模拟当前语言文案（等价于 `.tr()` 的全局 Localization.instance 返回值）。
String _lang = 'zh';

/// 模拟设置页里的 `const XxxSection()`：不订阅 Localizations，只读全局文案。
class _ConstSection extends StatelessWidget {
  const _ConstSection();

  @override
  Widget build(BuildContext context) => Text(_lang);
}

/// 只重建 [Localizations]，保持 child（设置主从布局）实例稳定，
/// 复现「切语言时路由页并不重建，详情面板需自行订阅 locale 才能刷新」的场景。
class _LocaleScope extends StatefulWidget {
  const _LocaleScope({super.key, required this.child});

  final Widget child;

  @override
  State<_LocaleScope> createState() => _LocaleScopeState();
}

class _LocaleScopeState extends State<_LocaleScope> {
  Locale _locale = const Locale('zh');

  void switchTo(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: _locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: widget.child,
    );
  }
}

void main() {
  testWidgets('设置详情面板在未重建的父级下也能随语言刷新（const 子组件）', (tester) async {
    _lang = 'zh';
    final scopeKey = GlobalKey<_LocaleScopeState>();
    final splitView = SettingsSplitView(
      destinations: [
        SettingsDestination(
          title: 'title',
          subtitle: 'subtitle',
          icon: HugeIcons.strokeRoundedSettings01,
          builder: (_) => const _ConstSection(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _LocaleScope(key: scopeKey, child: splitView),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('zh'), findsOneWidget);

    _lang = 'en';
    scopeKey.currentState!.switchTo(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('en'), findsOneWidget);
    expect(find.text('zh'), findsNothing);
  });
}
