import 'package:anoxia/features/note/presentation/widgets/note_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('导入保留段落内换行和 CRLF', () {
    expect(markdownToDocument('第一行\n第二行').toPlainText(), '第一行\n第二行\n');
    expect(markdownToDocument('\uFEFF第一行\r\n第二行').toPlainText(), '第一行\n第二行\n');
  });

  test('导入保留标题、列表和代码块', () {
    final doc = markdownToDocument(
      '# 标题\n\n- 第一项\n- 第二项\n\n```\nfoo\nbar\n```',
    );
    expect(doc.toPlainText(), contains('foo\nbar'));
    final ops = doc.toDelta().toJson();
    expect(
      ops.any(
        (op) =>
            op['attributes'] is Map && (op['attributes'] as Map)['header'] == 1,
      ),
      isTrue,
    );
    expect(
      ops.any(
        (op) =>
            op['attributes'] is Map &&
            (op['attributes'] as Map)['list'] == 'bullet',
      ),
      isTrue,
    );
  });
}
