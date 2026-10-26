import 'package:anoxia/domain/ai_reply_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('接受完整数组并去重，不展示破碎 JSON 或混合类型', () {
    expect(parseAiReplySuggestions('```json\n["改天吧", "改天吧", "周日方便吗"]\n```'), [
      '改天吧',
      '周日方便吗',
    ]);
    for (final raw in [
      '["只生成一半',
      '["a", 42]',
      '{"reply":"a"}',
      '好的\n收到',
      '[]',
    ]) {
      expect(parseAiReplySuggestions(raw), isEmpty);
    }
    expect(parseAiReplySuggestions('["${'a' * 2001}"]'), isEmpty);
  });
}
