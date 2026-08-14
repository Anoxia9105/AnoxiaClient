import 'package:anoxia/features/settings/presentation/widgets/settings_chat_focus_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the focus mode switch and reports changes', (
    tester,
  ) async {
    bool? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsChatFocusSection(
            enabled: false,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    final switchFinder = find.byKey(const Key('chat-focus-mode-switch'));
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pump();

    expect(changedValue, isTrue);
  });
}
