import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/chat/media/media_timeline_provider.dart';
import 'package:anoxia/common/utils/message_url_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<MediaTimelineSection> page(List<ChatMessage> source, {int? cursor}) =>
      queryTimelinePage(
        pageSize: 3,
        beforeSeq: cursor,
        accepts: (m) => extractChatMessageUrls(m).isNotEmpty,
        query: (before, limit) async => source
            .where((m) => before == null || m.seq! < before)
            .take(limit)
            .toList(),
      );
  List<ChatMessage> source(int count, {bool Function(int)? linked}) => [
    for (var seq = count; seq > 0; seq--)
      ChatMessage(
        messageId: '$seq',
        seq: seq,
        content: (linked?.call(seq) ?? true)
            ? 'https://example.com/$seq'
            : '普通文本',
      ),
  ];

  test('有效链接恰好满页：没有虚假的加载更多按钮', () async {
    final result = await page(source(3));
    expect(result.items.length, 3);
    expect(result.hasMore, isFalse);
  });
  test('后续源页只有普通文本：不误报更多链接', () async {
    final result = await page(source(12, linked: (seq) => seq >= 10));
    expect(result.items.length, 3);
    expect(result.hasMore, isFalse);
  });
  test('跨越无链接页探测下一条，翻页不丢失或重复', () async {
    final messages = source(16, linked: (seq) => seq >= 14 || seq == 1);
    final first = await page(messages);
    expect(first.hasMore, isTrue);
    final second = await page(messages, cursor: first.oldestSeq);
    expect(second.items.map((m) => m.seq), [1]);
    expect(second.hasMore, isFalse);
  });
}
