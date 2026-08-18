import 'package:anoxia/common/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  tearDown(() {
    Toast.messengerKey.currentState?.clearSnackBars();
  });

  testWidgets('文本通知使用无图标的浮动 SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: Toast.messengerKey,
        home: const Scaffold(),
      ),
    );

    Toast.showToast('保存成功', type: ToastType.success);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('保存成功'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(HugeIcon),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      findsNothing,
    );
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
      SnackBarBehavior.floating,
    );
  });

  testWidgets('成功失败警告和信息使用不同的语义颜色', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: Toast.messengerKey,
        home: const Scaffold(),
      ),
    );

    const expectedColors = <ToastType, Color>{
      ToastType.success: Color(0xFF2E7D32),
      ToastType.error: Color(0xFFB3261E),
      ToastType.warning: Color(0xFF8A5A00),
      ToastType.info: Color(0xFF455A64),
    };
    for (final entry in expectedColors.entries) {
      final type = entry.key;
      Toast.showToast(type.name, type: type);
      await tester.pump();
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        entry.value,
      );
      Toast.messengerKey.currentState!.clearSnackBars();
      await tester.pump();
    }
  });

  testWidgets('新通知会替换当前 SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: Toast.messengerKey,
        home: const Scaffold(),
      ),
    );

    Toast.showToast('第一条');
    Toast.showToast('第二条');
    await tester.pump();

    expect(find.text('第一条'), findsNothing);
    expect(find.text('第二条'), findsOneWidget);
  });

  testWidgets('提示条占满屏幕宽度并保持在屏幕底部', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: Toast.messengerKey,
        home: const Scaffold(),
      ),
    );

    Toast.showToast('占满宽度');
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.width, double.infinity);
    expect(snackBar.margin, isNull);

    final snackBarRect = tester.getRect(find.byType(SnackBar));
    final screenSize = tester.getSize(find.byType(MaterialApp));
    expect(snackBarRect.width, moreOrLessEquals(screenSize.width));
    expect(
      snackBarRect.bottom,
      moreOrLessEquals(screenSize.height, epsilon: 60),
    );
  });

  testWidgets('文字颜色随背景亮度自适应', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: Toast.messengerKey,
        home: const Scaffold(),
      ),
    );

    Toast.showToast('深色背景', type: ToastType.info);
    await tester.pump();
    Text text = tester.widget<Text>(find.text('深色背景'));
    expect(text.style!.color, Colors.white);

    Toast.messengerKey.currentState!.clearSnackBars();
    await tester.pump();
    Toast.showNotificationNow('浅色背景', color: const Color(0xFFFEF7FF));
    await tester.pump();
    text = tester.widget<Text>(find.text('浅色背景'));
    expect(text.style!.color, Colors.black);
  });
}
