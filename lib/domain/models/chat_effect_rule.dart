import 'dart:convert';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 声明式特效词库。后续新增祝福只需添加规则，不改消息收发链路。
class ChatEffectRule {
  const ChatEffectRule({
    required this.id,
    required this.keywords,
    required this.emojis,
    this.duration = const Duration(milliseconds: 3500),
  });

  final String id;
  final List<String> keywords;
  final List<String> emojis;
  final Duration duration;
}

const chatEffectRules = [
  ChatEffectRule(
    id: 'birthday',
    keywords: [
      '生日快乐',
      'happy birthday',
      '誕生日おめでとう',
      'たんじょうびおめでとう',
      'ハッピーバースデー',
    ],
    emojis: ['🎂', '🎂', '🍰', '🎈'],
  ),
  ChatEffectRule(
    id: 'miss_you',
    keywords: ['想你了', 'miss you', '会いたい', 'あいたい'],
    emojis: ['⭐', '🌟', '✨'],
  ),
];

/// 只识别当前消息的可见正文，绝不扫描载荷 JSON、引用或转发内容。
ChatEffectRule? matchChatEffect(
  ChatMessage message, {
  List<ChatEffectRule> rules = chatEffectRules,
}) {
  if (message.payload?.forwardInfo != null) return null;
  final String text;
  switch (message.messageType) {
    case MessageType.text:
      text = message.content;
    case MessageType.richText:
      try {
        final delta = jsonDecode(message.payload?.quillDelta ?? '');
        if (delta is! List) return null;
        final buffer = StringBuffer();
        for (final operation in delta) {
          if (operation is! Map) return null;
          final insert = operation['insert'];
          // embed 前后保留边界，避免「生日 + 图片 + 快乐」被拼成触发词。
          buffer.write(insert is String ? insert : '\n');
        }
        text = buffer.toString();
      } on FormatException {
        return null;
      }
    default:
      return null;
  }
  final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  for (final rule in rules) {
    if (rule.emojis.isEmpty) continue;
    for (final keyword in rule.keywords) {
      final needle = keyword.toLowerCase();
      final matches = RegExp(r'[a-z]').hasMatch(needle)
          ? RegExp(
              '(?<![a-z0-9_])${RegExp.escape(needle)}(?![a-z0-9_])',
            ).hasMatch(normalized)
          : normalized.contains(needle);
      if (matches) return rule;
    }
  }
  return null;
}
