// AI 消息工具的 prompt 组装与文本提取（P0-3 翻译 + 未读总结）。
//
// 全部为纯函数（无 Flutter/riverpod 依赖），便于单测：
// - [messagePlainText]：消息 → 参与处理的纯文本。优先 `payload.content`
//   （richText 分支服务端已存 plainText）；`content` 若是历史遗留的
//   Quill Delta JSON（`[{"insert":...}]` 形态）就地展平；首位兜底原文。
// - [collectUnreadSummaryDraft]：把未读消息整理成总结草稿（纯文本行 +
//   媒体/其他类型计数，媒体不上正文只进统计）。
// - [buildTranslatePrompt] / [buildUnreadSummaryPrompt]：客户端组 prompt，
//   目标语言跟随当前 UI locale，与 ai_chat_controller 的做法一致
//   （服务端 `/chat/ai/stream` 不注入任务语义，prompt 全由客户端负责）。
// - [aiLanguageName]：locale.languageCode → 语言显示名（zh/en/ja 三语在册，
//   其它回退原码）。
import 'dart:convert';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 消息去媒体后的纯文本（仅用于翻译/总结 prompt 与展示，不改存储）
String messagePlainText(ChatMessage message) {
  final payloadContent = message.payload?.content;
  if (payloadContent != null && payloadContent.trim().isNotEmpty) {
    return payloadContent.trim();
  }
  final content = message.content;
  if (content.trim().isEmpty) return '';
  return _unwrapDelta(content).trim();
}

/// 历史遗留的富文本缓存行 `content` 可能是 Quill Delta JSON，
/// 形态为 `[{"insert":"..."},...]`；确认是 Delta JSON 就展平成纯文本。
String _unwrapDelta(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('[{')) return content;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! List) return content;
    final buffer = StringBuffer();
    for (final item in decoded) {
      if (item is Map) {
        final insert = item['insert'];
        if (insert is String) buffer.write(insert);
      }
    }
    return buffer.toString();
  } catch (_) {
    return content;
  }
}

/// 是否值得给 AI 处理（翻译入口用它判断：类型在册 + 有非空文本）
bool isTranslatableMessage(ChatMessage message) {
  final type = message.messageType;
  if (type != MessageType.text &&
      type != MessageType.richText &&
      type != MessageType.codeSnippet) {
    return false;
  }
  return messagePlainText(message).isNotEmpty;
}

/// 未读总结草稿：纯文本行 + 其他类型（媒体/文件等）计数
class UnreadSummaryDraft {
  const UnreadSummaryDraft({required this.lines, required this.otherCount});

  /// 可参与总结的文本行（按消息时间顺序：旧 → 新）
  final List<String> lines;

  /// 未读中无法上正文的其他类型消息数（图片/文件/语音等），只进统计
  final int otherCount;

  bool get isEmpty => lines.isEmpty;
}

/// 把未读消息整理成总结草稿（只收 text/richText/codeSnippet，其余计数）
UnreadSummaryDraft collectUnreadSummaryDraft(List<ChatMessage> messages) {
  final lines = <String>[];
  var otherCount = 0;
  for (final message in messages) {
    final type = message.messageType;
    final isText = type == MessageType.text ||
        type == MessageType.richText ||
        type == MessageType.codeSnippet;
    if (!isText) {
      otherCount++;
      continue;
    }
    final text = messagePlainText(message);
    if (text.isEmpty) {
      otherCount++;
      continue;
    }
    lines.add(text);
  }
  return UnreadSummaryDraft(lines: lines, otherCount: otherCount);
}

/// locale.languageCode → 语言显示名；未收录的回退原码
String aiLanguageName(String languageCode) {
  switch (languageCode) {
    case 'zh':
      return '简体中文';
    case 'en':
      return 'English';
    case 'ja':
      return '日本語';
    default:
      return languageCode;
  }
}

/// 翻译 prompt（只输出译文，不加解释/引号）
String buildTranslatePrompt(String text, {required String language}) {
  return '请把下面的内容翻译成「$language」。'
      '直接输出译文，不要解释、不要添加引号或前缀，'
      '代码片段保持原样不改写：\n\n$text';
}

/// 未读聊天记录总结 prompt
///
/// [maxLines] 限制送入 AI 的行数（防 prompt 过长）；超出的行按时间顺序
/// 丢弃最旧的并注明省略。
String buildUnreadSummaryPrompt(
  UnreadSummaryDraft draft, {
  required String language,
  int maxLines = 100,
}) {
  final allLines = draft.lines;
  final shown = allLines.length > maxLines ? allLines.sublist(allLines.length - maxLines) : allLines;
  final omitted = allLines.length - shown.length;

  final buffer = StringBuffer()
    ..writeln('下面是一段未读聊天记录。'
        '请用「$language」对大家讨论的内容做简要总结：'
        '列出最多 5 条要点短句，不要针对任何人发言，不要逐条复述。');
  if (otherLine(draft).isNotEmpty) {
    buffer.writeln(otherLine(draft));
  }
  if (omitted > 0) {
    buffer.writeln('（更早的 $omitted 条文本已省略）');
  }
  buffer.writeln('聊天记录：');
  for (final line in shown) {
    buffer.writeln('- $line');
  }
  return buffer.toString();
}

/// 媒体/其他类型统计行的文案（拼进 prompt 出处说明）
String otherLine(UnreadSummaryDraft draft) {
  if (draft.otherCount <= 0) return '';
  return '（另有 ${draft.otherCount} 条图片/文件/语音等其他消息未包含在记录中）';
}
