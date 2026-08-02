import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatFavorite V5 typed payload 解析', () {
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
  });
}
