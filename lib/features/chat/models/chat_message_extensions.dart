import 'package:characters/characters.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 消息相关的 UI 判断扩展
extension ChatMessageUIExtension on ChatMessage {
  /// 判断消息是否需要气泡背景
  bool get needsBubble {
    switch (messageType) {
      case MessageType.richText:
      case MessageType.audio:
        return true;
      case MessageType.text:
        return !_isSingleEmoji;
      default:
        return false;
    }
  }

  /// 判断消息内容是否为单个表情（仅对文本/表情类型有效）
  bool get _isSingleEmoji {
    // 如果是 emoji 类型，认为是单个表情
    if (messageType == MessageType.emoji) return true;
    if (payload?.emojiCode?.isNotEmpty == true) return true;

    // 仅对 text 类型进一步检查
    if (messageType != MessageType.text) return false;

    final text = (payload?.content ?? content).trim();
    if (text.isEmpty) return false;
    final graphemes = text.characters;
    if (graphemes.length != 1) return false;

    final rune = graphemes.first.runes.firstOrNull;
    if (rune == null) return false;

    // 常见表情符号 Unicode 范围
    return rune >= 0x1F000 ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x2300 && rune <= 0x23FF);
  }
}