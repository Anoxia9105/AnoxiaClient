import 'package:anoxia/common/widgets/desktop/desktop_app_bar.dart';
import 'package:anoxia/features/chat/presentation/call/component/deesktop/call_desktop_app_bar.dart';
import 'package:anoxia/framework/provider/layout/window_maximized_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _WindowMaximized extends WindowMaximized {
  @override
  bool build() => false;
}

void main() {
  final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);
  late List<String> calls;
  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          calls.add(call.method);
          return call.method == 'isMaximized' ? false : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  for (final callWindow in [false, true]) {
    Future<void> mount(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            windowMaximizedProvider.overrideWith(_WindowMaximized.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: callWindow
                  ? const CallDesktopAppbar(title: '通话')
                  : const DesktopAppBar(title: Text('Anoxia')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('${callWindow ? '通话' : '主窗口'} macOS Logo 在最右侧且不显示重复控件', (
      tester,
    ) async {
      await mount(tester);
      expect(find.byTooltip('header_minimize'), findsNothing);
      expect(find.byTooltip('header_maximize'), findsNothing);
      expect(find.byTooltip('header_closure'), findsNothing);
      final bar = tester.getRect(find.byType(AppBar));
      final logo = tester.getRect(find.byType(Image));
      expect(logo.right, closeTo(bar.right - 20, 1));
      expect(tester.widget<AppBar>(find.byType(AppBar)).leadingWidth, 80);
      expect(calls, isNot(contains('isMaximized')));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    }, variant: macOS);

    testWidgets('${callWindow ? '通话' : '主窗口'} Windows 保留自定义窗口控制', (
      tester,
    ) async {
      await mount(tester);
      expect(find.byTooltip('header_minimize'), findsOneWidget);
      expect(find.byTooltip('header_maximize'), findsOneWidget);
      expect(find.byTooltip('header_closure'), findsOneWidget);
      expect(tester.getRect(find.byType(Image)).left, lessThan(80));
      await tester.tap(find.byTooltip('header_minimize'));
      await tester.pump();
      expect(calls, contains('minimize'));
      await tester.pumpWidget(const SizedBox());
    }, variant: windows);
  }
}
