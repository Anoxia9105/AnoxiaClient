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
}
