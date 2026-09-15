import 'package:flutter_quill/flutter_quill.dart';

/// 从原始 Delta ops 提取纯文本，绕过 flutter_quill Document。
String quillPlainTextFromOps(List<dynamic>? opsJson) {
  if (opsJson is! List) return '';
  final buffer = StringBuffer();
  for (final op in opsJson) {
    if (op is! Map) continue;
    final insert = op['insert'];
    if (insert is String) {
      buffer.write(insert);
    }
  }
  return buffer.toString();
}

/// 拼接用于链接预览的源文本：纯文本 + 各 op 的 link 属性。
String quillLinkPreviewSource(List<dynamic>? opsJson) {
  final buffer = StringBuffer(quillPlainTextFromOps(opsJson));
  if (opsJson is! List) return buffer.toString();

  for (final op in opsJson) {
    if (op is! Map) continue;
    final attributes = op['attributes'];
    if (attributes is! Map) continue;
    final link = attributes['link']?.toString();
    if (link == null || link.isEmpty) continue;
    buffer
      ..write(' ')
      ..write(link);
  }
  return buffer.toString();
}

/// 判断 Delta 是否需要占据整行宽度（代码块、列表或非 mention embed）。
///
/// 代码块的行号、列表的项目符号/编号占的是**引导槽**（`indentWidthBuilder` 的左侧
/// 宽度），纯文本测量看不到这段槽位；列表的宽度也无法按最长行收缩，否则正文可用
/// 宽度不足会让行尾最后一个字提前换行。故与代码块同样处理：占满消息宽度。
bool quillRequiresFullWidth(List<dynamic>? opsJson) {
  if (opsJson is! List) return false;

  for (final op in opsJson) {
    if (op is! Map) continue;
    final insert = op['insert'];
    final attributes = op['attributes'];
    if (attributes is Map) {
      if (attributes.containsKey(Attribute.codeBlock.key) ||
          attributes.containsKey(Attribute.list.key)) {
        return true;
      }
    }
    if (insert is Map && !insert.containsKey('mention')) return true;
  }
  return false;
}
