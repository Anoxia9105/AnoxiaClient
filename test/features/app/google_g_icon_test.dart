import 'package:anoxia/features/app/presentation/widgets/google_g_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GoogleGIcon 绘制不抛异常', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GoogleGIcon())),
    );
    expect(find.byType(GoogleGIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
