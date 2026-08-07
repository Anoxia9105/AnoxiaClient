import 'package:anoxia/features/chat/presentation/widgets/message_render/code/code_block_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
      );

  testWidgets('默认不渲染行号', (tester) async {
    await tester.pumpWidget(wrap(const CodeBlockView(code: 'a\nb\nc')));

    expect(find.text('1'), findsNothing);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('showLineNumbers 开启时渲染行号', (tester) async {
    await tester.pumpWidget(
      wrap(const CodeBlockView(code: 'a\nb\nc', showLineNumbers: true)),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });
}
