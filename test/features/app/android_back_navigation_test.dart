import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Android 返回优先关闭弹窗和子路由，根路由才调用原生返回', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'chat',
              builder: (_, _) => const Scaffold(body: Text('Chat')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/chat');
    await tester.pumpAndSettle();
    showDialog<void>(
      context: tester.element(find.text('Chat')),
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
