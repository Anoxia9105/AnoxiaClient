import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('文字颜色按钮使用当前文字颜色并加粗图标', (tester) async {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatQuillColorStyleButton(
            controller: controller,
            type: ChatQuillColorStyleType.foreground,
            tooltip: '文字颜色',
            onPressed: () {},
          ),
        ),
      ),
    );

    controller.formatSelection(const ColorAttribute('#FFFF0000'));
    await tester.pump();

    final button = tester.widget<IconButton>(find.byType(IconButton));
    final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
    expect(button.isSelected, isTrue);
    expect(icon.color, const Color(0xFFFF0000));
    expect(icon.strokeWidth, 2.5);

    controller.formatSelection(Attribute.clone(Attribute.color, null));
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isFalse,
    );
    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).strokeWidth, 1.5);
  });

  testWidgets('背景颜色按钮使用当前背景色并加粗图标', (tester) async {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatQuillColorStyleButton(
            controller: controller,
            type: ChatQuillColorStyleType.background,
            tooltip: '背景颜色',
            onPressed: () {},
          ),
        ),
      ),
    );

    controller.formatSelection(const BackgroundAttribute('#FFFFFF00'));
    await tester.pump();

    final button = tester.widget<IconButton>(find.byType(IconButton));
    final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
    final backgroundColor = button.style?.backgroundColor?.resolve({});
    expect(button.isSelected, isTrue);
    expect(backgroundColor, isNull);
    expect(icon.color, const Color(0xFFFFFF00));
    expect(icon.strokeWidth, 2.5);
  });
}
