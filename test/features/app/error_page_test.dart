import 'package:anoxia/features/app/presentation/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('国际化尚未初始化时错误页使用内置文案且不二次报错', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorPage(details: 'No GoRouter found in context'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('页面渲染出错'), findsOneWidget);
    expect(find.text('No GoRouter found in context'), findsOneWidget);
    expect(find.text('复制错误信息'), findsOneWidget);
  });
}
