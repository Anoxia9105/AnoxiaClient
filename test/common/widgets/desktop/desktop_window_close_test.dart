import 'package:anoxia/common/widgets/desktop/desktop_app_bar.dart';
import 'package:anoxia/common/widgets/desktop/desktop_window_close_behavior.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:anoxia/framework/provider/layout/window_maximized_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('关闭策略读取实时开关，开启隐藏，关闭退出且重复关闭只退出一次', () async {
    final calls = <String>[];
    const channel = MethodChannel('window_manager');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final window = _MainWindow();
    await window.onWindowClose();
    expect(calls, ['hide']);
    expect(window.exits, 0);
    window.minimizeToTray = false;
    await window.onWindowClose();
    await window.onWindowClose();
    expect(window.exits, 1);
    expect(calls, ['hide']);
  });

  for (final minimized in [false, true]) {
    test('托盘打开窗口先恢复再显示和聚焦：minimized=$minimized', () async {
      final calls = <String>[];
      const channel = MethodChannel('window_manager');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return call.method == 'isMinimized' ? minimized : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await _MainWindow().showMainWindow();
      expect(calls, ['isMinimized', if (minimized) 'restore', 'show', 'focus']);
    });
  }

  testWidgets('标题栏关闭按钮发送关闭请求，由窗口监听器决定退出或驻留托盘', (tester) async {
    final calls = <String>[];
    const channel = MethodChannel('window_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return call.method == 'isMaximized' ? false : null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [windowMaximizedProvider.overrideWith(_WindowMaximized.new)],
        child: const MaterialApp(home: Scaffold(appBar: DesktopAppBar())),
      ),
    );
    await tester.tap(find.byTooltip('header_closure'));
    await tester.pump();
    expect(calls, contains('close'));
    expect(calls, isNot(contains('hide')));
  });
}

class _MainWindow with WindowListener, DesktopWindowCloseBehavior {
  @override
  bool minimizeToTray = true;
  int exits = 0;

  @override
  Future<void> exitApplication() async {
    exits++;
  }
}

class _WindowMaximized extends WindowMaximized {
  @override
  bool build() => false;
}
