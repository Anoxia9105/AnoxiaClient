/// 记事本 Markdown 导入 / 导出转换
///
/// - 导出：Delta → Markdown（自实现，覆盖标题/列表/任务/引用/代码块/
///   链接/粗斜下划线删除线/行内代码/对齐，颜色与图片 URL 简化处理）
/// - 导入：Markdown → HTML（package:markdown）→ Delta（HtmlToDelta）
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;

/// Delta → Markdown 文本
String deltaToMarkdown(Document document) {
  final lines = <_MdLine>[];
  final buffer = StringBuffer();

  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is String) {
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final segment = parts[i];
        if (segment.isNotEmpty) {
          buffer.write(_inlineWrap(segment, op.attributes));
        }
        if (i < parts.length - 1) {
          lines.add(_MdLine(buffer.toString(), op.attributes));
          buffer.clear();
        }
      }
    } else if (data is Map && data['image'] != null) {
      buffer.write('![image](${data['image']})');
    } else if (data is Map && data['video'] != null) {
      buffer.write('${data['video']}');
    } else if (data is Map && data['divider'] != null) {
      // 写成 `- - -` 而非 `---`：分割线紧贴上一行文字时 `---` 会被
      // Markdown 重新解析为 setext 二级标题（与 flutter_quill 内置
      // markdown 导出策略一致），`- - -` 可保证往返无损
      buffer.write('- - -');
    } else if (data is Map && data['custom'] != null) {
      final custom = data['custom'];
      if (custom is Map && custom['content'] != null) {
        buffer.write(custom['content'].toString());
      }
    }
  }
  // 收尾：无尾换行的最后一行
  if (buffer.isNotEmpty) {
    lines.add(_MdLine(buffer.toString(), null));
  }

  final out = StringBuffer();
  var inCodeBlock = false;
  for (final line in lines) {
    final isCode = line.attrs?['code-block'] == true;
    if (isCode) {
      if (!inCodeBlock) {
        out.writeln('```');
        inCodeBlock = true;
      }
      out.writeln(line.text);
    } else {
      if (inCodeBlock) {
        out.writeln('```');
        inCodeBlock = false;
      }
      out.writeln(_blockWrap(line));
    }
  }
  if (inCodeBlock) {
    out.writeln('```');
  }
  return out.toString().trimRight();
}

/// Markdown → Document（Quill Delta）
Document markdownToDocument(String markdown) {
  // 规范化：去 BOM、统一换行，避免空文件 / CRLF / BOM 导致转换异常
  final normalized = markdown
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceFirst(RegExp('^\uFEFF'), '');
  // 空文件 / 纯空白：直接返回空文档。
  // 否则 HtmlToDelta 会产出空 Delta，Document.fromDelta 会抛
  // `Document Delta cannot be empty.`，上层导入直接显示“导入失败”。
  if (normalized.trim().isEmpty) {
    return Document();
  }
  try {
    // flutter_quill_delta_from_html 不识别 <hr>，分割线会被静默丢弃；
    // 且其不会在相邻块级元素间补换行。这里先把 <hr> 替换成哨兵文本，
    // 转换完成后再还原为 divider 嵌入，并保证分割线独占一行。
    //
    // 另：上游库把 <p> 归为 inline（isBlock=false），导致连续段落
    // 的 <p><p> 不会在块间补换行，`第一行\n\n第二行` 会被合并为
    // `第一行第二行\n`（换行丢失、全部挤成一行）。这里通过 isBlockValidator
    // 将 <p> 视为块级，确保段落间保留换行。
    //
    // 兼容旧版导出的 <center>：上游库不识别该标签会静默丢弃内容，
    // 先转为 <p align="center"> 再走正常流程，保证往返不丢字。
    var preprocessed = normalized.replaceAllMapped(
      RegExp('<center>(.*?)</center>', caseSensitive: false, dotAll: true),
      (m) => '<p align="center">${m.group(1)}</p>',
    );
    final html = md
        .markdownToHtml(preprocessed)
        .replaceAllMapped(_hrTagPattern, (_) => _hrSentinel);
    final delta = HtmlToDelta(
      isBlockValidator: (name) =>
          const {
            'p',
            'h1',
            'h2',
            'h3',
            'h4',
            'h5',
            'h6',
            'ul',
            'ol',
            'li',
            'blockquote',
            'pre',
            'div',
            'hr',
            'table',
          }.contains(name),
    ).convert(html);
    return Document.fromDelta(
      _ensureDocumentDelta(_restoreHorizontalRules(delta)),
    );
  } catch (_) {
    // 转换失败回退为纯文本；同样保证 Delta 以换行结尾，
    // 否则 Document.fromDelta 在 debug 下断言失败、release 下文档非法
    try {
      var fallback = normalized;
      if (!fallback.endsWith('\n')) fallback = '$fallback\n';
      if (fallback.trim().isEmpty) return Document();
      return Document.fromDelta(_ensureDocumentDelta(Delta()..insert(fallback)));
    } catch (_) {
      return Document();
    }
  }
}

/// 保证 Delta 符合 Document 要求：非空且以换行结尾。
///
/// HtmlToDelta 对 `<center>` / 纯图片等输入可能产出不以 `\n` 结尾的
/// Delta，Document.fromDelta 在 debug 下直接断言失败，
/// release 下则得到非法文档（后续编辑/保存异常）。
Delta _ensureDocumentDelta(Delta delta) {
  if (delta.isEmpty) return Delta()..insert('\n');
  final last = delta.last;
  if (last.isInsert &&
      last.data is String &&
      (last.data as String).endsWith('\n')) {
    return delta;
  }
  delta.insert('\n');
  return delta;
}

final RegExp _hrTagPattern = RegExp(r'<hr\s*/?>', caseSensitive: false);

/// `<hr>` 哨兵字符（私用区字符，正常内容不会出现）
const String _hrSentinel = '\uE000\uE001';

/// 把哨兵文本还原为水平分割线嵌入。
Delta _restoreHorizontalRules(Delta input) {
  final out = Delta();

  // 分割线必须独占一行：上一行未以换行结尾时补一个换行，
  // 否则嵌入会与前面的文字挤在同一行，导出时还会被拼成一段
  void ensureLineBreak() {
    if (out.isEmpty) return;
    final last = out.last;
    if (last.isInsert &&
        last.data is String &&
        (last.data as String).endsWith('\n')) {
      return;
    }
    out.insert('\n');
  }

  for (final op in input.toList()) {
    if (!op.isInsert ||
        op.data is! String ||
        !(op.data as String).contains(_hrSentinel)) {
      out.push(op);
      continue;
    }
    final segments = (op.data as String).split(_hrSentinel);
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].isNotEmpty) {
        out.insert(segments[i], op.attributes);
      }
      if (i < segments.length - 1) {
        ensureLineBreak();
        out.insert(const {'divider': 'hr'});
        out.insert('\n');
      }
    }
  }
  return out;
}

/// 行内样式 → Markdown 包装
String _inlineWrap(String text, Map<String, dynamic>? attrs) {
  attrs ??= const {};
  final code = attrs['code'] == true;
  final link = attrs['link'];
  var s = text;

  if (code) {
    s = '`$s`';
  } else {
    final bold = attrs['bold'] == true;
    final italic = attrs['italic'] == true;
    final underline = attrs['underline'] == true;
    final strike = attrs['strike'] == true;
    if (bold) s = '**$s**';
    if (italic) s = '*$s*';
    if (underline) s = '<u>$s</u>';
    if (strike) s = '~~$s~~';
  }
  if (link is String && link.isNotEmpty) {
    s = '[$s]($link)';
  }
  return s;
}

/// 块级样式 → Markdown 行前缀
String _blockWrap(_MdLine line) {
  final attrs = line.attrs ?? const <String, dynamic>{};
  final header = attrs['header'];
  final list = attrs['list'];
  final blockquote = attrs['blockquote'] == true;
  final align = attrs['align'];

  if (blockquote) return '> ${line.text}';
  if (header == 1) return '# ${line.text}';
  if (header == 2) return '## ${line.text}';
  if (header == 3) return '### ${line.text}';
  if (list == 'bullet') return '- ${line.text}';
  if (list == 'ordered') return '1. ${line.text}';
  if (list == 'checked') return '- [x] ${line.text}';
  if (list == 'unchecked') return '- [ ] ${line.text}';
  // 居中/右对齐统一用 <p align>：HtmlToDelta 可识别并还原 align，
  // 此前 <center> 会被上游库静默丢弃，导致“导出→导入”内容丢失。
  if (align == 'center') return '<p align="center">${line.text}</p>';
  if (align == 'right') return '<p align="right">${line.text}</p>';
  return line.text;
}

/// 一行内容（含块级属性）
class _MdLine {
  final String text;
  final Map<String, dynamic>? attrs;

  const _MdLine(this.text, this.attrs);
}
