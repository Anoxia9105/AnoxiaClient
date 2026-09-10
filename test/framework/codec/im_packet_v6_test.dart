import 'dart:typed_data';

import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/protocol/message/event_message.dart';
import 'package:anoxia/framework/protocol/message/announcement_event.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 固定 wire fixture 按权威 im.proto 编写，不能用待测生成类序列化，
  // 否则陈旧的字段号会在 roundtrip 中相互抵消。外层为 ServerFrame 字段 17。
  for (final fixture in [
    (
      type: SystemEventType.userOnline,
      timestamp: 1788747599055,
      bytes: <int>[
        0x8a, 0x01, 0x0b,
        0x08, 0x07, // type = ONLINE (1)
        0x10, 0xcf, 0x99, 0xa9, 0xcd, 0x87, 0x34, // timestamp (2)
        0x28, 0x03, // operator = 3 (5)
      ],
    ),
    (
      type: SystemEventType.userOffline,
      timestamp: 1788747631539,
      bytes: <int>[
        0x8a, 0x01, 0x0b,
        0x08, 0x08, // type = OFFLINE (1)
        0x10, 0xb3, 0x97, 0xab, 0xcd, 0x87, 0x34, // timestamp (2)
        0x28, 0x03, // operator = 3 (5)
      ],
    ),
  ]) {
    test('固定 wire ${fixture.type} 保留用户 3 和服务端时间戳', () {
      final bytes = Uint8List.fromList(fixture.bytes);
      final decoded = ImPacketV6.decodeServerFrame(bytes);
      expect(decoded?.type, 'event');
      final event = decoded!.data as EventMessage;
      expect(event.eventType, fixture.type);
      expect(event.operatorId, 3);
      expect(event.timestamp, fixture.timestamp);
      expect(event.extra, isEmpty);
      final proto = v6.ServerFrame.fromBuffer(bytes).systemEvent;
      expect(proto.hasOperatorUserId(), isTrue);
      expect(proto.hasTargetUserId(), isFalse);
    });
  }

  test('固定 wire 系统事件保留 fallback、metadata 和可选 target', () {
    final bytes = Uint8List.fromList([
      0x8a, 0x01, 0x1b,
      0x08, 0x07,
      0x10, 0xcf, 0x99, 0xa9, 0xcd, 0x87, 0x34,
      0x1a, 0x02, 0x6f, 0x6b, // fallback_text (3) = "ok"
      0x22, 0x08, 0x0a, 0x03, 0x76, 0x69, 0x61,
      0x12, 0x01, 0x77, // metadata (4) = {"via": "w"}
      0x28, 0x03, // operator (5) = 3
      0x30, 0x09, // target (6) = 9
    ]);
    final decoded = ImPacketV6.decodeServerFrame(bytes);
    expect(decoded?.type, 'event');
    final event = decoded!.data as EventMessage;
    expect(event.eventType, SystemEventType.userOnline);
    expect(event.operatorId, 3);
    expect(event.timestamp, 1788747599055);
    expect(event.content, 'ok');
    expect(event.extra, {'via': 'w', 'targetUserId': 9});
    final proto = v6.ServerFrame.fromBuffer(bytes).systemEvent;
    expect(proto.metadata, {'via': 'w'});
    expect(proto.hasTargetUserId(), isTrue);
    expect(proto.targetUserId.toInt(), 9);
  });

  test('未指定系统事件不能被解码成联系人请求', () {
    final bytes = v6.ServerFrame(
      systemEvent: v6.SystemEvent(type: v6.SystemEventType.valueOf(0)),
    ).writeToBuffer();

    final decoded = ImPacketV6.decodeServerFrame(bytes);
    expect(
      decoded?.data is EventMessage
          ? (decoded!.data as EventMessage).eventType
          : null,
      isNot(SystemEventType.contactRequest),
    );
  });

  test('send message is a raw V6 ClientFrame and preserves cache identity', () {
    const message = RoomMessage(
      messageId: '',
      clientMsgId: 'client-1',
      roomId: 'room-1',
      senderId: 7,
      messageType: MessageType.text,
      payload: MessagePayload(content: 'hello'),
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
      type: v6.CallSignalType.CALL_SIGNAL_TYPE_INVITE,
      content: '{}',
    );

    final frame = v6.ClientFrame.fromBuffer(bytes);
    expect(frame.callSignal.hasTargetUserId(), isFalse);
  });

  test('announcement notification maps only identity revision and action', () {
    final bytes = v6.ServerFrame(
      announcementEvent: v6.AnnouncementEvent(
        id: fixnum.Int64(8),
        revision: 4,
        action: v6.AnnouncementAction.ANNOUNCEMENT_ACTION_UPDATED,
      ),
    ).writeToBuffer();

    final decoded = ImPacketV6.decodeServerFrame(Uint8List.fromList(bytes));
    final event = decoded!.data as AnnouncementEvent;

    expect(decoded.type, 'announcement');
    expect(event.id, 8);
    expect(event.revision, 4);
    expect(event.action, AnnouncementAction.updated);
  });
}
