import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatFavorite typed payload 解析', () {
    test('richText typed payload 提取摘要与详情文本', () {
      final favorite = ChatFavorite.fromJson({
        'id': 1,
        'msgId': 'm1',
        'favoriteType': 'RICH_TEXT',
        'senderId': 42,
        'payload':
            '{"richText":{"plainText":"你好世界","deltaJson":"[{\\"insert\\":\\"你好世界\\"}]"}}',
        'createdAt': '2026-08-02 10:00:00',
      });

      expect(favorite.messageType, MessageType.richText);
      expect(favorite.summary, contains('你好世界'));
      expect(favorite.detailText, contains('你好世界'));
    });

    test('text typed payload 提取正文', () {
      final favorite = ChatFavorite.fromJson({
        'id': 2,
        'msgId': 'm2',
        'favoriteType': 'TEXT',
        'payload': '{"text":{"text":"这是一条文本","interaction":null}}',
      });

      expect(favorite.messageType, MessageType.text);
      expect(favorite.summary, '这是一条文本');
    });

    test('image typed payload 推断类型并生成可读摘要', () {
      final favorite = ChatFavorite.fromJson({
        'id': 3,
        'msgId': 'm3',
        'favoriteType': '',
        'payload':
            '{"image":{"image":{"url":"https://x.com/a.jpg","width":100,"height":100},"caption":"风景照"}}',
      });

      expect(favorite.messageType, MessageType.image);
      expect(favorite.summary, '风景照');
      expect(favorite.detailText, '风景照');
    });

    test('video typed payload 推断类型', () {
      final favorite = ChatFavorite.fromJson({
        'id': 4,
        'msgId': 'm4',
        'favoriteType': '',
        'payload':
            '{"video":{"video":{"url":"https://x.com/v.mp4"},"durationMs":5000}}',
      });

      expect(favorite.messageType, MessageType.video);
    });

    test('file typed payload 无 caption 时摘要取文件名', () {
      final favorite = ChatFavorite.fromJson({
        'id': 5,
        'msgId': 'm5',
        'favoriteType': 'FILE',
        'payload':
            '{"file":{"file":{"url":"https://x.com/report.pdf","name":"季度报告.pdf"}}}',
      });

      expect(favorite.summary, '季度报告.pdf');
    });

    test('平铺 quillDelta 仍可解析为富文本', () {
      final favorite = ChatFavorite.fromJson({
        'id': 6,
        'msgId': 'm6',
        'favoriteType': '',
        'payload': '{"quillDelta":"[{\\"insert\\":\\"旧格式\\"}]"}',
      });

      expect(favorite.messageType, MessageType.richText);
      expect(favorite.summary, contains('旧格式'));
    });

    test('无内容时详情文本为空占位', () {
      final favorite = ChatFavorite.fromJson({
        'id': 7,
        'msgId': 'm7',
        'favoriteType': 'TEXT',
        'content': '',
        'payload': '',
      });

      expect(favorite.messageType, MessageType.text);
      expect(favorite.detailText, '');
    });

    test('payload 为对象时位置消息提取地点名称', () {
      final favorite = ChatFavorite.fromJson({
        'id': 8,
        'msgId': 'm8',
        'favoriteType': 'LOCATION',
        'content': '[location]',
        'payload': {
          'location': {
            'latitude': 34.26,
            'longitude': 108.94,
            'title': '钟楼',
            'address': '西安市莲湖区北大街',
          },
        },
      });

      expect(favorite.messageType, MessageType.location);
      expect(favorite.summary, '钟楼');
      expect(favorite.detailText, contains('钟楼'));
    });

    test('平铺位置 payload 无标题时提取地址', () {
      final favorite = ChatFavorite.fromJson({
        'id': 9,
        'msgId': 'm9',
        'favoriteType': 'LOCATION',
        'content': '[location]',
        'payload': {
          'latitude': 34.26,
          'longitude': 108.94,
          'address': '西安市莲湖区北大街',
        },
      });

      expect(favorite.messageType, MessageType.location);
      expect(favorite.summary, contains('西安市莲湖区北大街'));
    });

    test('位置无名称与地址时降级展示经纬度', () {
      final favorite = ChatFavorite.fromJson({
        'id': 10,
        'msgId': 'm10',
        'favoriteType': 'LOCATION',
        'content': '[location]',
        'payload': '{"location":{"latitude":34.26,"longitude":108.94}}',
      });

      expect(favorite.messageType, MessageType.location);
      expect(favorite.summary, contains('34.26'));
      expect(favorite.summary, contains('108.94'));
    });

    test('image typed payload toChatMessage 保留图片附件', () {
      final favorite = ChatFavorite.fromJson({
        'id': 8,
        'msgId': 'm8',
        'favoriteType': 'IMAGE',
        'payload':
            '{"image":{"image":{"url":"https://x.com/a.jpg","width":100,"height":100},"caption":"风景照"}}',
      });

      final message = favorite.toChatMessage();
      expect(message.messageType, MessageType.image);
      final attachments = message.payload?.mediaAttachments;
      expect(attachments, isNotEmpty);
      expect(attachments!.single.url, 'https://x.com/a.jpg');
    });

    test('image attachments 字段 toChatMessage 保留图片附件', () {
      final favorite = ChatFavorite.fromJson({
        'id': 9,
        'msgId': 'm9',
        'favoriteType': 'IMAGE',
        'content': '风景照',
        'attachments': '[{"url":"https://x.com/b.jpg","width":200,"height":300}]',
      });

      final message = favorite.toChatMessage();
      expect(message.messageType, MessageType.image);
      final attachments = message.payload?.mediaAttachments;
      expect(attachments, isNotEmpty);
      expect(attachments!.single.url, 'https://x.com/b.jpg');
    });

    test('video typed payload toChatMessage 保留视频与封面', () {
      final favorite = ChatFavorite.fromJson({
        'id': 10,
        'msgId': 'm10',
        'favoriteType': 'VIDEO',
        'payload':
            '{"video":{"video":{"url":"https://x.com/v.mp4"},"cover":{"url":"https://x.com/cover.jpg"},"durationMs":5000}}',
      });

      final message = favorite.toChatMessage();
      expect(message.messageType, MessageType.video);
      final attachments = message.payload?.mediaAttachments;
      expect(attachments, isNotEmpty);
      expect(attachments!.first.url, 'https://x.com/v.mp4');
    });
  });
}
