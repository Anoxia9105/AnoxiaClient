import 'package:anoxia/features/chat/application/saved_message_payload.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('收藏发送保留媒体和正文，移除来源会话的回复与提醒', () {
    const original = MessagePayload(
      content: 'caption',
      replyTo: 'old-message',
      mentions: [42],
      mentionAll: true,
      video: Attachment(url: 'https://example.com/video.mp4', kind: 'VIDEO'),
      cover: Attachment(url: 'https://example.com/cover.jpg', kind: 'IMAGE'),
    );
    final result = savedMessagePayload(original);
    expect(result.content, 'caption');
    expect(result.video?.url, original.video?.url);
    expect(result.cover?.url, original.cover?.url);
    expect(result.replyTo, isNull);
    expect(result.mentions, isNull);
    expect(result.mentionAll, isNull);
    expect(result.forwardInfo, isNull);
  });

  test('收藏发送保留富文本与结构化名片', () {
    const original = MessagePayload(
      quillDelta: '[{"insert":"hello\\n"}]',
      card: CardPayload(cardType: 'contact', entityId: '42', title: 'Alice'),
    );
    final result = savedMessagePayload(original);
    expect(result.quillDelta, original.quillDelta);
    expect(result.card?.entityId, '42');
  });
}
