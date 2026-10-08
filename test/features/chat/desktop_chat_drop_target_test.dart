import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/desktop_chat_drop_target.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

Future<void> _nativeEvent(
  WidgetTester tester,
  String method,
  dynamic arguments,
) async {
  final done = Completer<void>();
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'desktop_drop',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) => done.complete(),
  );
  await done.future.timeout(const Duration(seconds: 5));
}

Future<void> _pump(
  WidgetTester tester, {
  String roomId = 'room1',
  bool enabled = true,
  Brightness brightness = Brightness.light,
  Future<void> Function(List<PlatformFile>, bool Function())? onFiles,
  void Function(List<String>)? onRejected,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh')],
      startLocale: const Locale('zh'),
      path: 'assets/i18n',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData(
            brightness: brightness,
            fontFamily: 'NotoSansSC',
            colorSchemeSeed: Colors.teal,
          ),
          home: DesktopChatDropTarget(
            roomId: roomId,
            enabled: enabled,
            onFiles: onFiles ?? (_, _) async {},
            onRejected: onRejected ?? (_) {},
            child: const Scaffold(
              body: Center(child: Text('聊天消息')),
              bottomNavigationBar: SizedBox(height: 80, child: TextField()),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

void _desktopTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  // 原生消息处理注册在 fake async zone，文件 I/O 则由系统推进。
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(ready(), isTrue, reason: '文件处理应在限定时间内完成');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalizationController.initEasyLocation();
    final loader = FontLoader('NotoSansSC')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/NotoSansSC[wght].ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final brightness in Brightness.values) {
    _desktopTest('原生拖入和拖出提示（${brightness.name}）不抢编辑器焦点', (tester) async {
      await _pump(tester, brightness: brightness);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      await _nativeEvent(tester, 'entered', [200.0, 200.0]);
      await tester.pumpAndSettle();
      expect(find.text('松开以添加文件'), findsOneWidget);
      expect(find.text('文件会加入输入框，确认后再发送'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(focus));
      await expectLater(
        find.byType(DesktopChatDropTarget),
        matchesGoldenFile('goldens/desktop_drop_${brightness.name}.png'),
      );
      await _nativeEvent(tester, 'exited', null);
      await tester.pumpAndSettle();
      expect(find.text('松开以添加文件'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  _desktopTest('禁用房间和移动端不接收拖放', (tester) async {
    await _pump(tester, enabled: false);
    await _nativeEvent(tester, 'entered', [100.0, 100.0]);
    await tester.pumpAndSettle();
    expect(find.text('松开以添加文件'), findsNothing);
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pump(tester);
    expect(find.byType(DropTarget), findsNothing);
  });

  _desktopTest('输入框区域也接受原生释放事件，文件只加入草稿', (tester) async {
    final dir = Directory.systemTemp.createTempSync('anoxia_drop_widget_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/报告.pdf')..writeAsStringSync('pdf');
    final received = <PlatformFile>[];
    final done = Completer<void>();
    await _pump(
      tester,
      onRejected: (names) => fail('文件不应被拒绝: $names'),
      onFiles: (files, isActive) async {
        expectSync(isActive(), isTrue);
        received.addAll(files);
        done.complete();
      },
    );
    final point = tester.getCenter(find.byType(TextField));
    await _nativeEvent(tester, 'entered', [point.dx, point.dy]);
    await tester.pumpAndSettle();
    expect(find.text('松开以添加文件'), findsOneWidget);
    await _nativeEvent(tester, 'performOperation', [file.path]);
    await _pumpUntil(tester, () => done.isCompleted);
    await tester.pumpAndSettle();
    expect(received.single.name, '报告.pdf');
    expect(received.single.bytes, isNull);
    expect(find.text('正在准备文件…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  _desktopTest('切换会话使未完成的附件插入失效', (tester) async {
    final dir = Directory.systemTemp.createTempSync('anoxia_drop_race_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/file.txt')..writeAsStringSync('text');
    final started = Completer<void>();
    final finish = Completer<void>();
    bool Function()? active;
    await _pump(
      tester,
      onFiles: (files, isActive) async {
        active = isActive;
        started.complete();
        await finish.future;
      },
    );
    await _nativeEvent(tester, 'entered', [200.0, 200.0]);
    await _nativeEvent(tester, 'performOperation', [file.path]);
    await _pumpUntil(tester, () => started.isCompleted);
    expect(active!(), isTrue);
    // 保持同一个 State，更换房间必须使旧批次失效。
    await _pump(tester, roomId: 'room2', settle: false);
    expect(active!(), isFalse);
    finish.complete();
    await tester.pumpAndSettle();
    expect(find.text('松开以添加文件'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  _desktopTest('弹窗覆盖聊天时暂停文件拖放', (tester) async {
    await _pump(tester);
    final context = tester.element(find.byType(TextField));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('弹窗')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isFalse);
    await _nativeEvent(tester, 'entered', [100.0, 100.0]);
    await tester.pumpAndSettle();
    expect(find.text('松开以添加文件'), findsNothing);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isTrue);
  });

  _desktopTest('小窗口高文字缩放仍能显示拖放提示', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    await _nativeEvent(tester, 'entered', [100.0, 100.0]);
    await tester.pumpAndSettle();
    expect(find.text('松开以添加文件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
