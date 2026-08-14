import 'package:anoxia/features/settings/presentation/widgets/settings_chat_density_section.dart';
import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('展示三种聊天内容密度并可以切换', (tester) async {
    ChatContentDensity? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsChatDensitySection(
            selectedDensity: ChatContentDensity.comfortable,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('chat-density-comfortable')), findsOneWidget);
    expect(find.byKey(const Key('chat-density-compact')), findsOneWidget);
    expect(find.byKey(const Key('chat-density-flat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-density-flat')));
    await tester.pump();

    expect(selected, ChatContentDensity.flat);
  });
}
