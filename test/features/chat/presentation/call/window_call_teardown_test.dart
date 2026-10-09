import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/call/window_call_page.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_connection_warmup.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_loading_state.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Window extends Fake implements WindowController {
  _Window(this.arguments);

  @override
  final String arguments;
}

class _Room extends RoomController {
  final released = Completer<void>();
  int leaveCount = 0;
  CallInitialMedia? mediaAtConnect;

  @override
  Future<RoomState> build(String token) {
    mediaAtConnect = ref.read(callInitialMediaProvider('room'));
    return Completer<RoomState>().future;
  }

  @override
  Future<void> leave() {
    leaveCount++;
    return released.future;
  }
}

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const nativeWindow = MethodChannel('window_manager');
  const windowChannels = MethodChannel(
    'mixin.one/desktop_multi_window/channels',
  );
  // 平台覆盖必须由 variant 在测试体内设置并还原：flutter_test 在用例体结束、
  // tearDown 之前就会断言 debugDefaultTargetPlatformOverride 已复位。
  final windowsPlatform = TargetPlatformVariant.only(TargetPlatform.windows);
  late List<MethodCall> windowCalls;
  late List<MethodCall> channelCalls;
  Map<String, Object>? pendingAcceptance;
  int tokenFetches = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    windowCalls = [];
    channelCalls = [];
    pendingAcceptance = null;
    tokenFetches = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(nativeWindow, (call) async {
      windowCalls.add(call);
      if (call.method == 'isPreventClose') return true;
      if (call.method == 'isMaximized') return false;
      return null;
    });
    messenger.setMockMethodCallHandler(windowChannels, (call) async {
      channelCalls.add(call);
      if (call.method == 'invokeMethod' &&
          call.arguments['method'] == 'on_call_window_ready') {
        return pendingAcceptance;
      }
      return null;
    });
  });

  Future<void> mount(
    WidgetTester tester,
    _Room room, {
    bool join = false,
    bool ringing = false,
  }) async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          callConnectionWarmupProvider.overrideWith(
            (ref) => CallConnectionWarmup(() async {}),
          ),
          roomTokenProvider('room').overrideWith((ref) async {
            tokenFetches++;
            return 'actual-token';
          }),
          roomControllerProvider('actual-token').overrideWith(() => room),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en')],
          startLocale: const Locale('en'),
          path: 'assets/i18n',
          assetLoader: const _Translations(),
          child: WindowCallPage(
            controller: _Window(
              jsonEncode({
                'roomId': 'room',
                'title': 'Call teardown',
                if (!join && !ringing) 'token': 'actual-token',
                'session': 'window-session',
                'initialMedia': 'video',
                'join': join,
              }),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  // 调用系统窗口事件入口，不触发真实原生窗口或网络/媒体设备。
  Future<void> requestClose(WidgetTester tester) =>
      (tester.state(find.byType(WindowCallPage)) as dynamic).onWindowClose()
          as Future<void>;

  bool getDestroyed() => windowCalls.any(
    (call) =>
        call.method == 'close' ||
        (call.method == 'setPreventClose' &&
            call.arguments['isPreventClose'] == false),
  );

  bool hasChannelInvocation(String method) => channelCalls.any(
    (call) =>
        call.method == method || call.arguments.toString().contains(method),
  );

  testWidgets('窗口注册后领取早到接听，视频来电以语音接听不打开摄像头', (tester) async {
    pendingAcceptance = {
      'roomId': 'room',
      'session': 'window-session',
      'token': 'actual-token',
      'initialMedia': 'audio',
    };
    final room = _Room();
    await mount(tester, room, ringing: true);
    expect(find.byType(CallLoadingState), findsOneWidget);
    expect(room.mediaAtConnect, CallInitialMedia.audio);
    expect(tokenFetches, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windowsPlatform);

  testWidgets('窗口忽略上一通呼叫的迟到接听结果', (tester) async {
    tester.view.physicalSize = const Size(600, 344);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    pendingAcceptance = {
      'roomId': 'room',
      'session': 'old-session',
      'token': 'actual-token',
      'initialMedia': 'audio',
    };
    final room = _Room();
    await mount(tester, room, ringing: true);
    expect(room.mediaAtConnect, isNull);
    expect(tokenFetches, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windowsPlatform);

  testWidgets('接听不等待主窗口拉取令牌，子窗口立即加载连接', (tester) async {
    pendingAcceptance = {
      'roomId': 'room',
      'session': 'window-session',
      'initialMedia': 'audio',
    };
    final room = _Room();
    await mount(tester, room, ringing: true);
    expect(tokenFetches, 1);
    expect(room.mediaAtConnect, CallInitialMedia.audio);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windowsPlatform);

  testWidgets('媒体清理超过三秒仍保持窗口引擎，完成后才关闭', (tester) async {
    final room = _Room();
    await mount(tester, room);
    final closing = requestClose(tester);
    await tester.pump();
    expect(room.leaveCount, 1);
    expect(hasChannelInvocation('on_call_window_ending'), isTrue);
    expect(hasChannelInvocation('on_call_window_close'), isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(getDestroyed(), isFalse);

    room.released.complete();
    await tester.pump();
    await closing;
    expect(hasChannelInvocation('on_call_window_close'), isTrue);
    expect(windowCalls.where((call) => call.method == 'close'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windowsPlatform);

  testWidgets('媒体清理失败时保留窗口引擎', (tester) async {
    // 清理失败会走 FlutterError.reportError 上报，测试里捕获它：
    // 既不让 unittest 把它当成未处理异常，又能断言确实上报过。
    final reported = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
    try {
      final room = _Room();
      await mount(tester, room);
      final closing = requestClose(tester);
      await tester.pump();
      room.released.completeError(StateError('media release failed'));
      await tester.pump();
      await closing;
      expect(hasChannelInvocation('on_call_window_ending'), isTrue);
      expect(hasChannelInvocation('on_call_window_close'), isFalse);
      expect(reported, isNotEmpty);
      expect(getDestroyed(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      FlutterError.onError = previousOnError;
    }
  }, variant: windowsPlatform);

  testWidgets('加入时异步取得的实际 token 也必须先清理媒体', (tester) async {
    final room = _Room();
    await mount(tester, room, join: true);
    final closing = requestClose(tester);
    await tester.pump();
    expect(room.leaveCount, 1);
    expect(getDestroyed(), isFalse);
    room.released.complete();
    await tester.pump();
    await closing;
    expect(windowCalls.where((call) => call.method == 'close'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windowsPlatform);
}
