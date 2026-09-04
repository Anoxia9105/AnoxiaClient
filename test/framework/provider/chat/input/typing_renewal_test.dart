import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingSocket extends WsController {
  final typing = <bool>[];

  @override
  WsState build() => WsState(status: WsStatus.connected);

  @override
  void sendMessage(
    dynamic msg, {
    String? clientMsgId,
    Duration ackTimeout = const Duration(seconds: 15),
  }) {
    final frame = v6.ClientFrame.fromBuffer(msg as List<int>);
    typing.add(frame.typing.isTyping);
  }
}

void main() {
  testWidgets('持续输入每三秒续期，短时间按键不重复发送，停止两秒后结束', (tester) async {
    final socket = _RecordingSocket();
    final container = ProviderContainer(
      overrides: [
        wsControllerProvider.overrideWith(() => socket),
        currentRoomProvider(
          'room-1',
        ).overrideWithValue(ChatRoomVO(roomId: 'room-1', peerId: 42)),
        roomMembersProvider(
          'room-1',
        ).overrideWithValue([ChatRoomMemberVO(userId: 42, onlineStatus: true)]),
      ],
    );
    addTearDown(container.dispose);
    final input = container.read(
      chatInputControllerProvider('room-1').notifier,
    );

    input.handlePlainTextChanged('a');
    expect(socket.typing, [true]);
    for (var second = 1; second <= 6; second++) {
      await tester.pump(const Duration(seconds: 1));
      input.handlePlainTextChanged('a' * (second + 1));
      expect(socket.typing, List.filled(1 + second ~/ 3, true));
    }

    await tester.pump(const Duration(seconds: 2));
    expect(socket.typing, [true, true, true, false]);
  });
}
