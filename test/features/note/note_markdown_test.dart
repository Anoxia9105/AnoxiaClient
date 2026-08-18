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
      final doc = Document.fromDelta(Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Sub')
        ..insert('\n', {'header': 2}));
      expect(deltaToMarkdown(doc), '# Title\n## Sub');
    });

    test('粗体/斜体/链接', () {
      final doc = Document.fromDelta(Delta()
        ..insert('bold', {'bold': true})
        ..insert(' and ')
        ..insert('link', {'link': 'https://example.com'})
        ..insert('\n'));
      expect(
        deltaToMarkdown(doc),
        '**bold** and [link](https://example.com)',
      );
    });

    test('列表与任务项', () {
      final doc = Document.fromDelta(Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {'list': 'checked'}));
      expect(deltaToMarkdown(doc), '- a\n- [x] b');
    });

    test('代码块', () {
      final doc = Document.fromDelta(Delta()
        ..insert('int x = 1;')
        ..insert('\n', {'code-block': true}));
      expect(deltaToMarkdown(doc), '```\nint x = 1;\n```');
    });

    test('引用', () {
      final doc = Document.fromDelta(Delta()
        ..insert('quote')
        ..insert('\n', {'blockquote': true}));
      expect(deltaToMarkdown(doc), '> quote');
    });

    test('删除线/行内代码', () {
      final doc = Document.fromDelta(Delta()
        ..insert('gone', {'strike': true})
        ..insert(' and ')
        ..insert('code', {'code': true})
        ..insert('\n'));
      expect(deltaToMarkdown(doc), '~~gone~~ and `code`');
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
  });
}