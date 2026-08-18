import 'dart:convert';

import 'package:anoxia/features/note/presentation/widgets/note_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildNotePdf 生成合法 PDF（含 CJK 字体）', () async {
    final deltaJson = jsonEncode([
      {'insert': '标题'},
      {'insert': '\n', 'attributes': {'header': 1}},
      {'insert': '正文', 'attributes': {'bold': true}},
      {'insert': '\n'},
      {'insert': '项目A'},
      {'insert': '\n', 'attributes': {'list': 'bullet'}},
      {'insert': '代码块'},
      {'insert': '\n', 'attributes': {'code-block': true}},
    ]);
    final bytes = await buildNotePdf(
      title: '测试笔记',
      deltaJson: deltaJson,
      updatedAtLabel: '2026-08-18 10:00',
    );
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    expect(String.fromCharCodes(bytes), contains('%%EOF'));
  });

  test('buildNotePdf 空文档与坏 JSON 不抛异常', () async {
    final bytes = await buildNotePdf(title: '', deltaJson: 'not json');
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(1000));
  });
}
