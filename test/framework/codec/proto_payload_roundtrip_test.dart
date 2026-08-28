import 'package:anoxia/framework/codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoomMessage roundTrip(MessageType type, MessagePayload payload) {
    final frameBytes = ImPacketV5.encodeRoomMessageFrame(
      RoomMessage(
        messageId: '',
        clientMsgId: 'client-message-id',
        roomId: 'room-id',
        senderId: 7,
        messageType: type,
        payload: payload,
      ),
    );
    final frame = ImPacketV5.decodeFrame(frameBytes);
    expect(frame, isNotNull);
    final decoded = ImPacketV5.decodeRoomMessage(frame!.payload!);
    expect(decoded, isNotNull);
    return decoded!;
  }

  test('mentionAll survives V5 protobuf round trip', () {
    final message = roundTrip(
      MessageType.text,
      const MessagePayload(
        content: 'hello everyone',
        mentions: [8],
        mentionAll: true,
      ),
    );

    expect(message.payload?.mentions, [8]);
    expect(message.payload?.mentionAll, isTrue);
  });

  test('emoji fallback survives V5 protobuf round trip', () {
    final message = roundTrip(
      MessageType.emoji,
      const MessagePayload(content: '[派对鹦鹉]', emojiCode: 'party-parrot'),
    );

    expect(message.payload?.emojiCode, 'party-parrot');
    expect(message.payload?.content, '[派对鹦鹉]');
  });

  test('video interaction survives V5 protobuf round trip', () {
    final message = roundTrip(
      MessageType.video,
      const MessagePayload(
        content: '[video]',
        video: Attachment(
          id: 'video-1',
          kind: 'VIDEO',
          url: 'https://example.com/video.mp4',
        ),
        audioDuration: 5000,
        replyTo: 'message-3',
        mentionAll: true,
      ),
    );

    expect(message.payload?.replyTo, 'message-3');
    expect(message.payload?.mentionAll, isTrue);
  });
}
