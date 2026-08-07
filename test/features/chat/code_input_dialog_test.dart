import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/dialogs/code_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CodeInputDialog(onSubmit: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(EditableText), text);
    await tester.pump();
  }

  ColorScheme scheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

  Finder gutterBox(WidgetTester tester) => find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == scheme(tester).surfaceContainer,
      );

  testWidgets('行号区高度占满整个编辑器区域', (tester) async {
    await pumpDialog(tester);

    final editorBox = find.byWidgetPredicate(
      (w) =>
          w is ColoredBox && w.color == scheme(tester).surfaceContainerLow,
    );
    expect(editorBox, findsOneWidget);
    expect(gutterBox(tester), findsOneWidget);

    final editorSize = tester.getSize(editorBox);
    final gutterSize = tester.getSize(gutterBox(tester));
    expect(gutterSize.height, editorSize.height);
    // 编辑器区域高度与行号区一致，均占满对话框主体。
    expect(editorSize.height, greaterThan(300));
  });

  testWidgets('行号右对齐：数字右边缘与行号区右边缘留白一致', (tester) async {
    await pumpDialog(tester);
    await type(tester, 'a\nb\nc');

    final gutterRect = tester.getRect(gutterBox(tester));
    final numberRect = tester.getRect(find.text('3'));
    expect((gutterRect.right - numberRect.right).abs(), lessThan(9));
    expect((gutterRect.right - numberRect.right).abs(), greaterThan(7));
  });

  testWidgets('长行不软换行：编辑器宽度随内容增长而非换行', (tester) async {
    await pumpDialog(tester);
    final longLine = List.generate(300, (_) => 'x').join();
    await type(tester, longLine);

    // 单行输入：行号区只有一个行号，且代码宽度远超对话框可视宽度。
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    final editableSize = tester.getSize(find.byType(EditableText));
    final viewportWidth = tester.getSize(find.byType(Dialog)).width;
    expect(editableSize.width, greaterThan(viewportWidth + 1000));
  });

  testWidgets('多行：行号与行数一致且间距为等宽行高', (tester) async {
    await pumpDialog(tester);
    await type(tester, 'a\nb\nc\nd\ne');

    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);

    final firstTop = tester.getTopLeft(find.text('1')).dy;
    final secondTop = tester.getTopLeft(find.text('2')).dy;
    final thirdTop = tester.getTopLeft(find.text('3')).dy;
    final step = secondTop - firstTop;
    expect(step, greaterThan(10));
    expect((thirdTop - secondTop - step).abs(), lessThan(0.5));
  });

  testWidgets('空编辑器占满高度且可点击聚焦', (tester) async {
    await pumpDialog(tester);

    final editable = find.byType(EditableText);
    expect(editable, findsOneWidget);
    final editableSize = tester.getSize(editable);
    expect(editableSize.height, greaterThan(300));
    expect(editableSize.width, greaterThan(500));

    await tester.tap(editable);
    await tester.pump();
    expect(
      tester.widget<EditableText>(editable).focusNode.hasFocus,
      isTrue,
    );
  });
}
