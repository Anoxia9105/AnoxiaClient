import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  for (final width in [390.0, 1024.0]) {
    testWidgets('关于页反馈入口复用现有面板 $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final splitKey = GlobalKey<SettingsSplitViewState>();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSplitView(
              key: splitKey,
              destinations: [
                SettingsDestination(
                  title: '反馈',
                  subtitle: '',
                  icon: HugeIcons.strokeRoundedMessage02,
                  builder: (_) => Form(key: formKey, child: const Text('反馈表单')),
                ),
                SettingsDestination(
                  title: '关于',
                  subtitle: '',
                  showHeader: false,
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  builder: (detailContext) => TextButton(
                    key: const Key('open-feedback'),
                    onPressed: () {
                      final split = splitKey.currentState!;
                      if (split.isCompact) Navigator.of(detailContext).pop();
                      split.openDestination('反馈');
                    },
                    child: const Text('写反馈'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      splitKey.currentState!.openDestination('关于');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-feedback')));
      await tester.pumpAndSettle();
      expect(find.text('反馈表单'), findsOneWidget);
      expect(find.byKey(formKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
