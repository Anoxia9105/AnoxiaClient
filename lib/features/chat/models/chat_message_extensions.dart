import 'package:anoxia/common/utils/emoji_util.dart';
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
    return EmojiUtil.isSingleEmoji(text);
  }
}
