// 消息 URL 提取（P0-4 链接时间线口径）测试。
import 'package:anoxia/common/utils/message_url_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';

void main() {
  test('富文本正文和 link 属性均可提取并去重', () {
    final message = ChatMessage(payload: const MessagePayload(
      quillDelta: '[{"insert":"https://example.com"},{"insert":"文档","attributes":{"link":"https://docs.google.com/a"}},{"insert":"\\n"}]',
    ));
    expect(extractChatMessageUrls(message), ['https://example.com', 'https://docs.google.com/a']);
  });
  test('损坏 Delta 保留正文链接', () {
    expect(extractChatMessageUrls(ChatMessage(content: 'https://example.com',
      payload: const MessagePayload(quillDelta: '{'))), ['https://example.com']);
  });
  group('extractFirstMessageUrl', () {
    test('无 URL 返回 null', () {
      expect(extractFirstMessageUrl('今天天气不错'), isNull);
      expect(extractFirstMessageUrl(''), isNull);
    });

    test('提取第一个 http(s) URL', () {
      expect(
        extractFirstMessageUrl('看看这个 https://example.com/a?b=1 不错'),
        'https://example.com/a?b=1',
      );
      expect(
        extractFirstMessageUrl('ftp://x.com 不算 https://y.com'),
        'https://y.com',
      );
    });

    test('尾部标点自动剥离', () {
      expect(
        extractFirstMessageUrl('见 https://example.com/a 结束.'),
        'https://example.com/a',
      );
      expect(
        extractFirstMessageUrl('https://example.com/a?'),
        'https://example.com/a',
      );
      expect(
        extractFirstMessageUrl('https://example.com/a;'),
        'https://example.com/a',
      );
    });

    test('中文标点不剥离（固化 link_preview 原口径，两处展示一致）', () {
      expect(
        extractFirstMessageUrl('见 https://example.com/a，好'),
        'https://example.com/a，好',
      );
    });

    test('www. 前缀补全 https 协议', () {
      expect(extractFirstMessageUrl('上 www.example.com 找'),
          'https://www.example.com');
    });

    test('非法形态返回 null', () {
      // 有 https 前缀但无 host
      expect(extractFirstMessageUrl('https://'), isNull);
      expect(extractFirstMessageUrl('https:///path'), isNull);
      // 纯 "www." 无域名
      expect(extractFirstMessageUrl('www.'), isNull);
    });
  });

  group('extractMessageUrls', () {
    test('提取全部 URL 并去重（按出现顺序）', () {
      final urls = extractMessageUrls(
        'a https://a.com x https://b.com y https://a.com 尾 www.c.com',
      );
      expect(urls, [
        'https://a.com',
        'https://b.com',
        'https://www.c.com',
      ]);
    });

    test('全部无效返回空列表', () {
      expect(extractMessageUrls('https:// www. 中文'), isEmpty);
      expect(extractMessageUrls('none'), isEmpty);
    });

    test('与首条提取口径一致', () {
      final urls = extractMessageUrls('x https://first.com y https://two.com');
      expect(extractFirstMessageUrl('x https://first.com y https://two.com'),
          urls.first);
    });
  });
}
