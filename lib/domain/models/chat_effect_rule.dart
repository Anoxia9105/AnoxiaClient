import 'dart:convert';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 关键词的命中方式。
enum ChatEffectMatchMode {
  /// 正文里出现关键词即可（默认，适合短语与祝福语）。
  contains,

  /// 整条消息只由关键词本身构成（允许夹杂标点与重复），或关键词在句首
  /// 独立成词。专供「嘘」这类单字词，避免「吹嘘 / 嘘寒问暖」误触发。
  standalone,
}

/// 声明式特效词库。后续新增祝福只需添加规则，不改消息收发链路。
///
/// 词库约定：
/// - 每条规则默认只掉一种表情，画面干净（如「生日快乐」只掉 🎂）；
/// - 仅特殊节日（新年、圣诞）与「发财」允许混合多种表情；
/// - 规则按声明顺序匹配、先到先得：更具体的词必须排在更宽泛的词之前，
///   例如「发财」在「恭喜」之前，保证「恭喜发财」掉金币而不是 🎉；
/// - density > 1 表示「满屏」密度，实际粒子数由 ChatEffectLayer 按窗口宽度换算。
class ChatEffectRule {
  const ChatEffectRule({
    required this.id,
    required this.keywords,
    required this.emojis,
    this.duration = const Duration(milliseconds: 3500),
    this.density = 1,
    this.matchMode = ChatEffectMatchMode.contains,
  });

  final String id;
  final List<String> keywords;
  final List<String> emojis;
  final Duration duration;
  final double density;
  final ChatEffectMatchMode matchMode;
}

const chatEffectRules = [
  // ── 节日 / 祝福 ──────────────────────────────────────────────
  ChatEffectRule(
    id: 'birthday',
    keywords: [
      '生日快乐',
      'happy birthday',
      '誕生日おめでとう',
      'たんじょうびおめでとう',
      'ハッピーバースデー',
    ],
    emojis: ['🎂'], // 只掉生日蛋糕
  ),
  ChatEffectRule(
    id: 'new_year',
    keywords: [
      '新年快乐',
      '新春快乐',
      '春节快乐',
      'happy new year',
      'あけましておめでとう',
      '明けましておめでとう',
      'ハッピーニューイヤー',
    ],
    emojis: ['🧨', '🧧'], // 特殊节日：爆竹 + 红包混合
  ),
  ChatEffectRule(
    id: 'christmas',
    keywords: ['圣诞快乐', '圣诞节快乐', 'merry christmas', 'メリークリスマス'],
    emojis: ['🎄', '❄️'], // 特殊节日：圣诞树 + 雪花混合
  ),
  // 以下为扩展节日，不需要时可整条删除。
  ChatEffectRule(id: 'mid_autumn', keywords: ['中秋快乐', '中秋节快乐'], emojis: ['🥮']),
  ChatEffectRule(id: 'valentine', keywords: ['情人节'], emojis: ['🌹']),

  // ── 财运 / 喜庆 ──────────────────────────────────────────────
  // 「发财」必须排在「恭喜」之前：恭喜发财 → 金币雨，而不是 🎉。
  ChatEffectRule(
    id: 'fortune',
    keywords: ['发财', '财源广进'],
    emojis: ['🪙', '🧧', '💰'], // 金币 + 红包 + 钱袋（元宝无 Unicode 码位）
  ),
  ChatEffectRule(id: 'congrats', keywords: ['恭喜', '撒花'], emojis: ['🎉']),
  ChatEffectRule(
    id: 'merit',
    keywords: ['功德无量'],
    emojis: ['📿'], // 木鱼无 Unicode 码位，用念珠代替
  ),

  // ── 日常情绪 / 网络用语 ──────────────────────────────────────
  ChatEffectRule(
    id: 'kiss',
    keywords: [
      '么么哒',
      '想你了',
      '想你',
      '爱你',
      '爱心',
      'miss you',
      'love you',
      '会いたい',
      'あいたい',
      '愛してる',
    ],
    emojis: ['💋', '❤️'], // 满屏亲亲与红心
    density: 1.5,
  ),
  ChatEffectRule(
    id: 'stars',
    keywords: ['星星', '繁星'],
    emojis: ['⭐'], // 满天繁星
    density: 1.5,
  ),
  ChatEffectRule(id: 'cheer', keywords: ['加油'], emojis: ['💪']),
  ChatEffectRule(id: 'poop', keywords: ['吃屎'], emojis: ['💩'], density: 1.75),
  ChatEffectRule(id: 'clown', keywords: ['小丑'], emojis: ['🤡'], density: 1.75),
  ChatEffectRule(
    id: 'shh',
    keywords: ['嘘'],
    emojis: ['🤫'],
    density: 1.75,
    matchMode: ChatEffectMatchMode.standalone,
  ),
  ChatEffectRule(
    id: 'speechless',
    keywords: ['服了', '无语'],
    emojis: ['😓'],
    density: 1.75,
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
      final matches = switch (rule.matchMode) {
        ChatEffectMatchMode.standalone => _matchesStandalone(
          normalized,
          needle,
        ),
        ChatEffectMatchMode.contains => _matchesContains(normalized, needle),
      };
      if (matches) return rule;
    }
  }
  return null;
}

/// 拉丁字母关键词按整词匹配，避免 "miss you" 命中 "dismiss yourself"。
bool _matchesContains(String normalized, String needle) {
  if (RegExp(r'[a-z]').hasMatch(needle)) {
    return RegExp(
      '(?<![a-z0-9_])${RegExp.escape(needle)}(?![a-z0-9_])',
    ).hasMatch(normalized);
  }
  return normalized.contains(needle);
}

/// 单字 / 短词独立成句才算命中：
/// 1. 去掉标点、空白与符号后只剩关键词本身的重复（「嘘」「嘘！」「嘘嘘嘘」）；
/// 2. 关键词在句首且后面紧跟标点或空白（「嘘，别说话」），
///    但仍排除「嘘寒问暖」这类词内出现。
bool _matchesStandalone(String normalized, String needle) {
  if (normalized.isEmpty || !normalized.contains(needle)) return false;
  final stripped = normalized.replaceAll(
    RegExp(r'[\s\p{P}\p{S}]', unicode: true),
    '',
  );
  if (stripped.isNotEmpty && stripped.replaceAll(needle, '').isEmpty) {
    return true;
  }
  return RegExp(
    r'^' + RegExp.escape(needle) + r'(?=[\s\p{P}\p{S}]|$)',
    unicode: true,
  ).hasMatch(normalized);
}
