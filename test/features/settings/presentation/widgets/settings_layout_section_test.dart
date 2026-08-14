import 'package:anoxia/features/settings/presentation/widgets/settings_layout_section.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('展示三种桌面布局并可以切换选择', (tester) async {
    DesktopLayoutPreference? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsLayoutSection(
            selectedPreference: DesktopLayoutPreference.automatic,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('desktop-layout-auto')), findsOneWidget);
    expect(find.byKey(const Key('desktop-layout-card')), findsOneWidget);
    expect(find.byKey(const Key('desktop-layout-flat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('desktop-layout-flat')));
    await tester.pump();

    expect(selected, DesktopLayoutPreference.flat);
  });
}
