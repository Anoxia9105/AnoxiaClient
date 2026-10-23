import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('合并分栏不再绘制详情卡片且切换后保留选中项', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildApp(bool joined) => MaterialApp(
      home: Scaffold(
        body: SettingsSplitView(
          joinedPanels: joined,
          destinations: [
            SettingsDestination(
              title: '第一项',
              subtitle: '说明',
              icon: HugeIcons.strokeRoundedSettings01,
              builder: (_) => const Text('第一项内容'),
            ),
            SettingsDestination(
              title: '第二项',
              subtitle: '说明',
              icon: HugeIcons.strokeRoundedSettings01,
              builder: (_) => const Text('第二项内容'),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildApp(false));
    await tester.tap(find.byKey(const Key('settings-navigation-item-1')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildApp(true));
    await tester.pumpAndSettle();

    expect(find.text('第二项内容'), findsOneWidget);
    final decorations = tester.widgetList<DecoratedBox>(
      find.ancestor(
        of: find.text('第二项内容'),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(decorations, isNotEmpty);
    final panel = decorations.first.decoration as BoxDecoration;
    expect(panel.border, isNull);
    expect(panel.borderRadius, BorderRadius.zero);
    expect(tester.takeException(), isNull);
  });
}
