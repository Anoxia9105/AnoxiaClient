import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/protocol/i_packet.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/protocol/packet_frame.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ws extends WsController {
  final incoming = StreamController<PacketFrame<IPacket>>.broadcast();
  final sent = <v6.ClientFrame>[];
  @override
  WsState build() => WsState(status: WsStatus.connected);
  @override
  Stream<PacketFrame<IPacket>> get messageStream => incoming.stream;
  @override
  void sendMessage(
    dynamic msg, {
    String? clientMsgId,
    Duration ackTimeout = const Duration(seconds: 15),
  }) => sent.add(v6.ClientFrame.fromBuffer(msg as Uint8List));
}

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Ws ws;
  late ProviderContainer container;
  setUp(() {
    ws = _Ws();
    container = ProviderContainer(
      overrides: [
        wsControllerProvider.overrideWith(() => ws),
        authControllerProvider.overrideWith(_Auth.new),
        currentRoomProvider('group').overrideWith(
          (ref) => ChatRoomVO(roomId: 'group', roomName: '研发群', roomType: 1),
        ),
        currentRoomProvider('private').overrideWith((ref) => null),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await ws.incoming.close();
  });

  test('群通话挂断及重复关窗不广播结束，仍可再次加入后退出', () async {
    final controller = container.read(
      callInvitationControllerProvider.notifier,
    );
    container.read(callIsGroupProvider('group').notifier).state = true;
    await controller.endRoom('group');
    await controller.endRoom('group');
    expect(ws.sent, isEmpty);
    // 没有设置媒体标识时也能从会话资料识别群聊。
    container.read(callIsGroupProvider('group').notifier).state = false;
    await controller.endRoom('group');
    expect(ws.sent, isEmpty);
  });

  test('私聊挂断仍发送一次 HANGUP', () async {
    final controller = container.read(
      callInvitationControllerProvider.notifier,
    );
    await controller.endRoom('private');
    await controller.endRoom('private');
    expect(ws.sent, hasLength(1));
    expect(
      ws.sent.single.callSignal.type,
      v6.CallSignalType.CALL_SIGNAL_TYPE_HANGUP,
    );
  });

  test('旧客户端的群挂断信令不会关闭本端正在进行的通话', () async {
    container.read(callInvitationControllerProvider);
    final session = container.read(
      mobileCallSessionControllerProvider.notifier,
    );
    session.start(roomId: 'group', title: '研发群');
    ws.incoming.add(
      PacketFrame(
        topic: PacketType.highFrequency,
        data: const HighMessage(
          roomId: 'group',
          senderId: 2,
          type: HighMessageType.CALL_END,
          content: '{}',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(mobileCallSessionControllerProvider)?.roomId,
      'group',
    );
    expect(ws.sent, isEmpty);
  });

  test('定向邀请使用会话名称', () async {
    final controller = container.read(
      callInvitationControllerProvider.notifier,
    );
    await controller.inviteMembers(
      ChatRoomVO(roomId: 'group', roomName: '研发群', roomType: 1),
      [2],
    );
    final content = jsonDecode(ws.sent.single.callSignal.content) as Map;
    expect(content['title'], '研发群');
    expect(content['roomId'], 'group');
    expect(content['isGroup'], isTrue);
  });

  test('桌面窗口传来 LiveKit 房间 ID 时，主窗口仍用会话名称发邀请', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channels = MethodChannel('mixin.one/desktop_multi_window/channels');
    const windows = MethodChannel('mixin.one/desktop_multi_window');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windows, (_) async => 'test-window');
    messenger.setMockMethodCallHandler(channels, (_) async => true);
    addTearDown(() async {
      await Channel.callChannel.setMethodCallHandler(null);
      messenger.setMockMethodCallHandler(windows, null);
      messenger.setMockMethodCallHandler(channels, null);
    });
    await container
        .read(callWindowControllerProvider.notifier)
        .openCallWindow(
          themeIndex: 0,
          title: '研发群',
          roomId: 'group',
          isGroup: true,
        );
    const codec = StandardMethodCodec();
    final response = Completer<void>();
    // ignore: deprecated_member_use
    await messenger.handlePlatformMessage(
      channels.name,
      codec.encodeMethodCall(
        MethodCall('methodCall', {
          'channel': Channel.callChannel.name,
          'method': 'invite_call_members',
          'arguments': const {
            'roomId': 'group',
            'title': 'group',
            'userIds': [2],
          },
        }),
      ),
      (_) => response.complete(),
    );
    await response.future;
    final content = jsonDecode(ws.sent.single.callSignal.content) as Map;
    expect(content['title'], '研发群');
    expect(content['roomId'], 'group');
  });
}
