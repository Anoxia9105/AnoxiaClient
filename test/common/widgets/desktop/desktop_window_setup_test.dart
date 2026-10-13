import 'package:anoxia/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('macOS 初始化保留原生窗口按钮且不调用 Windows 图标接口', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('window_manager');
    const screen = MethodChannel('dev.leanflutter.plugins/screen_retriever');
    const display = {
      'id': 'mac-screen',
      'size': {'width': 1440.0, 'height': 900.0},
      'visibleSize': {'width': 1440.0, 'height': 875.0},
      'visiblePosition': {'dx': 0.0, 'dy': 25.0},
    };
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(screen, (
      call,
    ) async {
      return switch (call.method) {
        'getPrimaryDisplay' => display,
        'getAllDisplays' => {
          'displays': [display],
        },
        'getCursorScreenPoint' => {'dx': 700.0, 'dy': 400.0},
        _ => null,
      };
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        screen,
        null,
      ),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'setIcon') {
        throw MissingPluginException('macOS 不支持 setIcon');
      }
      if (call.method == 'getBounds') {
        return {'x': 0.0, 'y': 0.0, 'width': 800.0, 'height': 600.0};
      }
      if ([
        'isFullScreen',
        'isMaximized',
        'isMinimized',
      ].contains(call.method)) {
        return false;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await app.setupDesktopWindow(
      size: const Size(800, 600),
      minimumSize: const Size(600, 400),
    );
    await tester.pump();
    expect(calls.map((call) => call.method), isNot(contains('setIcon')));
    final style = calls.singleWhere(
      (call) => call.method == 'setTitleBarStyle',
    );
    expect(style.arguments['titleBarStyle'], 'hidden');
    expect(style.arguments['windowButtonVisibility'], isTrue);
    expect(calls.map((call) => call.method), containsAll(['show', 'focus']));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
