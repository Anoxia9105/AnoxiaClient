import 'package:anoxia/framework/protocol/message/message_payload.dart';

/// 解析记事本卡片内的内容（纯文本快照）。
///
/// 优先取 `properties['content']`；个别历史消息 / 双编码场景下
/// 换行符可能以字面 `\n` 形式存储，这里做防御性还原，保证多行渲染。
String resolveNoteCardContent(CardPayload card) {
  var content = card.properties['content'] ?? '';
  if (content.trim().isEmpty) {
    return card.displaySummary;
  }
  return unescapeEscapedNewlines(content);
}

/// 将字面转义序列还原为真实字符。
///
/// 仅当文本不含真实换行、且其中的反斜杠全部属于 `\n` / `\r` / `\t`
/// 转义序列（无其它反斜杠用法，如 Windows 路径）时执行，
/// 避免破坏正常包含反斜杠的笔记内容。
String unescapeEscapedNewlines(String text) {
  if (text.contains('\n')) return text;
  if (!text.contains(r'\n')) return text;
  final stripped = text
      .replaceAll(r'\n', '')
      .replaceAll(r'\r', '')
      .replaceAll(r'\t', '');
  if (stripped.contains(r'\')) return text;
  return text
      .replaceAll(r'\r\n', '\n')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\n')
      .replaceAll(r'\t', '\t');
}
