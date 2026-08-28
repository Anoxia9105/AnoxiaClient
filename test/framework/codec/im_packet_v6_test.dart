import 'dart:typed_data';

import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('send message is a raw V6 ClientFrame and preserves cache identity', () {
    final message = RoomMessage(
      messageId: '',
      clientMsgId: 'client-1',
      roomId: 'room-1',
      senderId: 7,
      messageType: MessageType.text,
      payload: const MessagePayload(content: 'hello'),
      clientTimestamp: 123,
    );

    final bytes = ImPacketV6.encodeRoomMessageFrame(message);
    final frame = v6.ClientFrame.fromBuffer(bytes);

    expect(frame.requestId, 'client-1');
    expect(frame.sendMessage.clientMessageId, 'client-1');
    expect(frame.sendMessage.roomId, 'room-1');
    expect(frame.sendMessage.payload.text.content, 'hello');
  });

  test('ACK keeps request correlation separate from server message id', () {
    final bytes = v6.ServerFrame(
      requestId: 'client-1',
      ack: v6.Ack(
        code: v6.AckCode.ACK_CODE_OK,
        roomId: 'room-1',
        messageId: 'server-1',
        seq: fixnum.Int64(42),
      ),
    ).writeToBuffer();

    final decoded = ImPacketV6.decodeServerFrame(bytes)!;
    final ack = decoded.data as AckV6;

    expect(decoded.requestId, 'client-1');
    expect(ack.clientMessageId, isNull);
    expect(ack.meta?.messageId, 'server-1');
    expect(ack.meta?.roomId, 'room-1');
    expect(ack.meta?.seq, 42);
  });

  test('typing and busy signals map to existing high-frequency consumers', () {
    final typing = v6.ServerFrame(
      typing: v6.TypingEvent(
        roomId: 'room-1',
        senderUserId: fixnum.Int64(7),
        isTyping: true,
        serverTimestampMs: fixnum.Int64(123),
      ),
    );
    final busy = v6.ServerFrame(
      callSignal: v6.CallSignal(
        roomId: 'room-1',
        senderUserId: fixnum.Int64(7),
        type: v6.CallSignalType.CALL_SIGNAL_TYPE_BUSY,
        content: '{}',
        serverTimestampMs: fixnum.Int64(124),
      ),
    );

    final typingMessage =
        ImPacketV6.decodeServerFrame(
              Uint8List.fromList(typing.writeToBuffer()),
            )!.data
            as HighMessage;
    final busyMessage =
        ImPacketV6.decodeServerFrame(
              Uint8List.fromList(busy.writeToBuffer()),
            )!.data
            as HighMessage;

    expect(typingMessage.type, HighMessageType.TYPING_STATUS);
    expect(typingMessage.content, 'true');
    expect(busyMessage.type, HighMessageType.CALL_BUSY);
  });

  test('group call target remains absent instead of becoming user zero', () {
    final bytes = ImPacketV6.encodeCallSignalFrame(
      roomId: 'room-1',
      type: v6.CallSignalType.CALL_SIGNAL_TYPE_INVITE.value,
      content: '{}',
    );

    final frame = v6.ClientFrame.fromBuffer(bytes);
    expect(frame.callSignal.hasTargetUserId(), isFalse);
  });
}
