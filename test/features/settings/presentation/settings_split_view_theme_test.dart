import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('compact settings detail uses theme surface colors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SettingsSplitView(
            destinations: [
              SettingsDestination(
                title: 'Appearance',
                subtitle: 'Theme settings',
                icon: HugeIcons.strokeRoundedColors,
                builder: (_) => const Text('Detail'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-navigation-item-0')));
    await tester.pumpAndSettle();

    final scaffoldColors = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .map((scaffold) => scaffold.backgroundColor);
    expect(scaffoldColors, contains(scheme.surface));
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      scheme.surface,
    );
  });
}
