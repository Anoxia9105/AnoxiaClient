import 'dart:async';

import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channels = MethodChannel('mixin.one/desktop_multi_window/channels');
  const windows = MethodChannel('mixin.one/desktop_multi_window');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final sent = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    sent.clear();
    messenger.setMockMethodCallHandler(windows, (call) async => 'test-window');
    messenger.setMockMethodCallHandler(channels, (call) async {
      sent.add(call);
      return true;
    });
  });
  tearDown(() async {
    await Channel.callChannel.setMethodCallHandler(null);
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(windows, null);
    messenger.setMockMethodCallHandler(channels, null);
  });

  Future<dynamic> ready(
    String session, {
    String? method,
    String roomId = 'room',
  }) async {
    const codec = StandardMethodCodec();
    final response = Completer<dynamic>();
    // 模拟子引擎通过插件发送就绪消息。
    // ignore: deprecated_member_use
    await messenger.handlePlatformMessage(
      channels.name,
      codec.encodeMethodCall(
        MethodCall('methodCall', {
          'channel': Channel.callChannel.name,
          'method': method ?? Channel.callWindowReadyMethod,
          'arguments': {'roomId': roomId, 'session': session},
        }),
      ),
      (data) => response.complete(codec.decodeEnvelope(data!)),
    );
    return response.future;
  }

  test('子窗口鉴权使用主窗口最新登录态，并拒绝旧会话和其他房间', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(callWindowControllerProvider.notifier);
    await controller.openCallWindow(
      themeIndex: 0,
      title: 'Peer',
      roomId: 'room',
    );
    final session = controller.activeSession!;
    final cache = container.read(tokenCacheProvider.notifier);
    cache.setToken('test-initial-login');
    expect(
      await ready(session, method: Channel.callWindowAuthMethod),
      'test-initial-login',
    );
    cache.setToken('test-current-login');
    expect(
      await ready(session, method: Channel.callWindowAuthMethod),
      'test-current-login',
    );
    expect(
      await ready('old-session', method: Channel.callWindowAuthMethod),
      isNull,
    );
    expect(
      await ready(
        session,
        method: Channel.callWindowAuthMethod,
        roomId: 'other',
      ),
      isNull,
    );
    cache.clearToken();
    expect(await ready(session, method: Channel.callWindowAuthMethod), isNull);
  });

  test('窗口未就绪时保留接听结果，过期窗口不能领取，就绪后直接推送', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(callWindowControllerProvider.notifier);
    await controller.openCallWindow(
      themeIndex: 0,
      title: 'Peer',
      roomId: 'room',
    );
    await controller.connectAcceptedCall(
      roomId: 'room',
      initialMedia: CallInitialMedia.audio,
    );
    expect(
      sent.where(
        (c) =>
            c.method == 'invokeMethod' &&
            c.arguments['method'] == Channel.callAcceptedMethod,
      ),
      isEmpty,
    );
    expect(await ready('old-session'), isNull);
    final pending = await ready(controller.activeSession!);
    expect(pending['initialMedia'], 'audio');
    expect(pending['session'], controller.activeSession);
    await controller.connectAcceptedCall(
      roomId: 'room',
      initialMedia: CallInitialMedia.video,
    );
    expect(
      sent.where(
        (c) =>
            c.method == 'invokeMethod' &&
            c.arguments['method'] == Channel.callAcceptedMethod,
      ),
      hasLength(1),
    );
  });
}
