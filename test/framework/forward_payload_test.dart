import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:fixnum/fixnum.dart';
import 'dart:typed_data';

void main() {
  test('固定 wire 字段 12 保留转发信息，避免陈旧生成代码相互抵消', () {
    final message =
        ImPacketV6.decodeServerFrame(
              Uint8List.fromList([
                0x52,
                0x16,
                0x2a,
                0x14, // ServerFrame.message / RoomMessage.payload
                0x0a, 0x07, 0x0a, 0x05, 104, 101, 108, 108, 111, // text: hello
                0x62,
                0x09,
                0x0a,
                0x05,
                65,
                108,
                105,
                99,
                101,
                0x10,
                0x7b, // forward_info: Alice, 123
              ]),
            )!.data
            as RoomMessage;
    expect(message.payload?.content, 'hello');
    expect(message.payload?.forwardInfo?.authorName, 'Alice');
    expect(message.payload?.forwardInfo?.originalTimestampMs, 123);
  });
  test('V6 下行转发标记与正文并存，上行不携带服务端标记', () {
    final frame = v6.ServerFrame(
      message: v6.RoomMessage(
        messageId: 'm1',
        roomId: 'target',
        seq: Int64(3),
        payload: v6.MessagePayload(
          text: v6.TextPayload(content: 'hello'),
          forwardInfo: v6.ForwardInfo(
            authorName: 'Alice',
            originalTimestampMs: Int64(123),
          ),
        ),
      ),
    );
    final message =
        ImPacketV6.decodeServerFrame(frame.writeToBuffer())!.data
            as RoomMessage;
    expect(message.payload?.content, 'hello');
    expect(message.payload?.forwardInfo?.authorName, 'Alice');
    final upstream = v6.ClientFrame.fromBuffer(
      ImPacketV6.encodeRoomMessageFrame(message),
    );
    expect(upstream.sendMessage.payload.text.content, 'hello');
    expect(
      upstream.sendMessage.payload.toProto3Json().toString(),
      isNot(contains('forwardInfo')),
    );
  });
  test('转发信息在历史 JSON 与本地缓存往返后保留', () {
    final payload = MessagePayload.fromJson({
      'text': {'text': 'hello'},
      'forwardInfo': {'authorName': 'Alice', 'originalTimestampMs': 123},
    });
    expect(payload.forwardInfo?.authorName, 'Alice');
    final cached = MessagePayload.fromJson(payload.toFlatJson());
    expect(cached.forwardInfo?.originalTimestampMs, 123);
    final typed = MessagePayload.fromJson(cached.toTypedJson(MessageType.text));
    expect(typed.forwardInfo?.authorName, 'Alice');
  });
}
