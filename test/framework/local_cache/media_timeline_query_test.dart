// P0-4 媒体时间线本地查询测试：类型过滤 / seq 倒序 / beforeSeq 分页 /
// 删除过滤。种子口径参照 local_data_source_consistency_test.dart。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalDataSource source;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = LocalDataSource(db);
  });
  tearDown(() => db.close());

  ChatMessage makeMessage(
    String id,
    MessageType type, {
    int? seq,
    MessagePayload? payload,
    String content = '',
  }) => ChatMessage(
    messageId: id,
    clientMsgId: 'client-$id',
    roomId: 'room',
    senderId: 1,
    seq: seq,
    timestamp: 1700000000000 + (seq ?? 0) * 1000,
    messageType: type,
    content: content,
    payload: payload,
    deliveryStatus: DeliveryStatus.sent,
  );

  MessagePayload imagePayload(String url) => MessagePayload(
    image: Attachment(url: url, name: 'p.png', kind: 'IMAGE', size: 123),
  );

  test('媒体查询只回 image/video，按 seq 新→旧倒序', () async {
    await source.upsertMessage(
      makeMessage('img1', MessageType.image, seq: 1, payload: imagePayload('a')),
    );
    await source.upsertMessage(
      makeMessage('txt', MessageType.text, seq: 2, content: 'https://a.com'),
    );
    await source.upsertMessage(
      makeMessage('vid', MessageType.video, seq: 3),
    );
    await source.upsertMessage(
      makeMessage('file', MessageType.file, seq: 4),
    );
    await source.upsertMessage(
      makeMessage('img2', MessageType.image, seq: 5, payload: imagePayload('b')),
    );

    final media = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.image.code, MessageType.video.code],
    );
    expect(media.map((m) => m.messageId), ['img2', 'vid', 'img1']);
  });

  test('beforeSeq 分页翻页：seq < beforeSeq', () async {
    for (var i = 1; i <= 5; i++) {
      await source.upsertMessage(
        makeMessage('img$i', MessageType.image, seq: i,
            payload: imagePayload('u$i')),
      );
    }
    final page1 = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.image.code],
      limit: 2,
    );
    expect(page1.map((m) => m.messageId), ['img5', 'img4']);

    final page2 = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.image.code],
      limit: 2,
      beforeSeq: page1.last.seq,
    );
    expect(page2.map((m) => m.messageId), ['img3', 'img2']);
  });

  test('已删除消息不进时间线', () async {
    await source.upsertMessage(
      makeMessage('alive', MessageType.image, seq: 1, payload: imagePayload('a')),
    );
    await source.upsertMessage(
      makeMessage('gone', MessageType.image, seq: 2, payload: imagePayload('g')),
    );
    // 撤回 = 保留行 + isDeleted（LocalDataSource.applyRecalls 口径）
    await source.applyRecalls(const ['gone']);
    final media = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.image.code],
    );
    expect(media.single.messageId, 'alive');
  });

  test('文件与链接分别按 file / text 过滤（richText 不进去）', () async {
    await source.upsertMessage(
      makeMessage('doc', MessageType.file, seq: 1, content: 'doc.pdf'),
    );
    await source.upsertMessage(
      makeMessage('plain', MessageType.text, seq: 2,
          content: '看 https://a.com'),
    );
    await source.upsertMessage(
      makeMessage('rich', MessageType.richText, seq: 3,
          content: '{"insert":"https://nope.com\\n"}'),
    );

    final files = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.file.code],
    );
    expect(files.single.messageId, 'doc');

    final texts = await source.getMediaTimelineMessages(
      'room',
      typeCodes: [MessageType.text.code],
    );
    expect(texts.single.messageId, 'plain');
  });
}
