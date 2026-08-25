import 'package:anoxia/features/note/presentation/widgets/note_markdown.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deltaToMarkdown', () {
    test('纯文本', () {
      final doc = Document.fromDelta(Delta()..insert('hello\nworld\n'));
      expect(deltaToMarkdown(doc), 'hello\nworld');
    });

    test('标题', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('Title')
          ..insert('\n', {'header': 1})
          ..insert('Sub')
          ..insert('\n', {'header': 2}),
      );
      expect(deltaToMarkdown(doc), '# Title\n## Sub');
    });

    test('粗体/斜体/链接', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('bold', {'bold': true})
          ..insert(' and ')
          ..insert('link', {'link': 'https://example.com'})
          ..insert('\n'),
      );
      expect(deltaToMarkdown(doc), '**bold** and [link](https://example.com)');
    });

    test('列表与任务项', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('a')
          ..insert('\n', {'list': 'bullet'})
          ..insert('b')
          ..insert('\n', {'list': 'checked'}),
      );
      expect(deltaToMarkdown(doc), '- a\n- [x] b');
    });

    test('代码块', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('int x = 1;')
          ..insert('\n', {'code-block': true}),
      );
      expect(deltaToMarkdown(doc), '```\nint x = 1;\n```');
    });

    test('引用', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('quote')
          ..insert('\n', {'blockquote': true}),
      );
      expect(deltaToMarkdown(doc), '> quote');
    });

    test('删除线/行内代码', () {
      final doc = Document.fromDelta(
        Delta()
          ..insert('gone', {'strike': true})
          ..insert(' and ')
          ..insert('code', {'code': true})
          ..insert('\n'),
      );
      expect(deltaToMarkdown(doc), '~~gone~~ and `code`');
    });

    test('水平分隔线导出为 - - -（避免被解析为 setext 标题）', () {
      final doc = Document.fromJson([
        {'insert': '标题\n'},
        {
          'insert': {'divider': 'hr'},
        },
        {'insert': '\n'},
        {'insert': '正文\n'},
      ]);
      expect(deltaToMarkdown(doc), '标题\n- - -\n正文');
    });
  });

  group('markdownToDocument', () {
    test('Markdown 解析为 Delta 并可导出回 Markdown', () {
      final md = '# Hello\n\n**bold** and [link](https://example.com)';
      final doc = markdownToDocument(md);
      final plain = doc.toPlainText();
      expect(plain, contains('Hello'));
      expect(plain, contains('bold'));
      expect(plain, contains('link'));
    });

    test('纯文本正常往返', () {
      final doc = markdownToDocument('plain only');
      expect(doc.toPlainText().trim(), 'plain only');
    });

    test('水平分隔线（---）导入为 divider 嵌入', () {
      // 回归：flutter_quill_delta_from_html 不识别 <hr>，此前分割线会被静默丢弃
      final doc = markdownToDocument('标题\n\n---\n\n正文');
      final ops = doc.toDelta().toList();
      expect(
        ops.any(
          (op) =>
              op.isInsert &&
              op.data is Map &&
              (op.data as Map)['divider'] != null,
        ),
        isTrue,
        reason: '`---` 应转换为 divider 嵌入而不是被丢弃',
      );
    });

    test('AI 输出含多条分割线时全部保留', () {
      final doc = markdownToDocument('第一段\n\n----------\n\n第二段\n\n---\n\n结尾');
      final ops = doc.toDelta().toList();
      final dividers = ops
          .where(
            (op) =>
                op.isInsert &&
                op.data is Map &&
                (op.data as Map)['divider'] != null,
          )
          .length;
      expect(dividers, 2);
      final plain = doc.toPlainText();
      expect(plain, contains('第一段'));
      expect(plain, contains('第二段'));
      expect(plain, contains('结尾'));
    });

    test('分割线导出后再导入保持往返一致', () {
      const md = '前文\n\n---\n\n后文';
      final exported = deltaToMarkdown(markdownToDocument(md));
      expect(exported, contains('- - -'));
      expect(deltaToMarkdown(markdownToDocument(exported)), exported);
    });

    test('连续分割线与首行分割线', () {
      // 分割线在文档开头
      var ops = markdownToDocument('---\n\n正文').toDelta().toList();
      expect(
        ops.any(
          (op) =>
              op.isInsert &&
              op.data is Map &&
              (op.data as Map)['divider'] != null,
        ),
        isTrue,
      );
      // 连续两条分割线
      ops = markdownToDocument('---\n\n---\n\n正文').toDelta().toList();
      final dividers = ops
          .where(
            (op) =>
                op.isInsert &&
                op.data is Map &&
                (op.data as Map)['divider'] != null,
          )
          .length;
      expect(dividers, 2);
    });
  });
}
