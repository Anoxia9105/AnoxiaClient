// 回复预览栏组件
//
// 在聊天输入框上方显示被引用消息的预览条，展示发送者、时间和内容摘要。
// 支持点击跳转到原消息、清除引用等操作。
import 'package:anoxia/common/utils/date_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 回复预览栏
///
/// 在输入框上方以紧凑的卡片形式展示被引用消息的预览信息，
/// 包括发送者名称、发送时间和消息内容摘要。
/// 支持紧凑模式（[dense]）和可选的操作按钮。
class ReplyPreviewBar extends ConsumerWidget {
  /// 被引用的消息对象，为 null 时显示「引用消息不存在」回退文本
  final ChatMessage? message;
  /// 清除引用回调，不为 null 时显示关闭按钮
  final VoidCallback? onClear;
  /// 点击预览栏的回调，不为 null 时启用点击效果
  final VoidCallback? onTap;
  /// 是否使用紧凑布局，减少间距和字号
  final bool dense;

  const ReplyPreviewBar({
    super.key,
    required this.message,
    this.onClear,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sender = _displaySender(ref, message);
    final time = DateUtil.formatTimestampToTime(message?.timestamp);
    final content = _displayContent(message);
    final bar = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dense ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: dense ? 10 : 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'chat_reply_cancel_tooltip'.tr(),
              onPressed: onClear,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return bar;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        child: IntrinsicWidth(child: bar),
      ),
    );
  }

  static String _displaySender(WidgetRef ref, ChatMessage? message) {
    if (message == null) return '';

    final currentUser = ref.watch(authControllerProvider).value;
    if (message.senderId != null && message.senderId == currentUser?.userId) {
      final name = currentUser?.nickName.trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final roomId = message.roomId;
    if (roomId != null && roomId.isNotEmpty && message.senderId != null) {
      final members = ref.watch(roomMembersProvider(roomId));
      for (final member in members) {
        if (member.userId == message.senderId) {
          final name = member.nickName?.trim();
          if (name != null && name.isNotEmpty) return name;
          break;
        }
      }
    }

    final senderId = message.senderId;
    if (senderId != null) return 'reply_user_prefix'.tr(args: ['$senderId']);
    return 'chat_unknown_user'.tr();
  }

  static String _displayContent(ChatMessage? message) {
    if (message == null) return 'chat_quote_not_found'.tr();

    final payload = message.payload;
    final content = (payload?.content ?? message.content).trim();
    // 非空且不是历史协议占位符（如 [code]/[video]/plaintext）时直接展示原文；
    // 文本/富文本/表情的用户原文即使形如 [code] 也是有效内容，不做过滤。
    if (content.isNotEmpty && !_isPlaceholderForType(content, message.messageType)) {
      return content;
    }

    return switch (message.messageType) {
      MessageType.image => 'reply_placeholder_image'.tr(),
      MessageType.audio => 'reply_placeholder_audio'.tr(),
      MessageType.video => 'reply_placeholder_video'.tr(),
      MessageType.file =>
        payload?.file?.name?.isNotEmpty == true
            ? '${'reply_placeholder_file'.tr()} ${payload!.file!.name}'
            : 'reply_placeholder_file'.tr(),
      MessageType.emoji =>
        payload?.asset?.url?.isNotEmpty == true
            ? 'reply_placeholder_emoji'.tr()
            : payload?.emojiCode?.isNotEmpty == true
            ? payload!.emojiCode!
            : 'reply_placeholder_emoji'.tr(),
      MessageType.system => 'reply_placeholder_system'.tr(),
      MessageType.card => 'reply_placeholder_card'.tr(),
      MessageType.location => 'reply_placeholder_location'.tr(),
      MessageType.codeSnippet => 'reply_placeholder_code'.tr(),
      MessageType.richText || MessageType.text => 'reply_placeholder_text'.tr(),
      null => 'reply_placeholder_text'.tr(),
    };
  }

  /// 历史协议占位符识别（需回退到本地化文案，而非展示英文原文）。
  ///
  /// 文本/富文本/表情消息永不视为占位（用户原文可能就是 "[code]"）。
  /// 仅代码类型识别 `[dart]` 这类语言占位与裸 `plaintext`。
  static bool _isPlaceholderForType(String content, MessageType? type) {
    if (type == MessageType.text ||
        type == MessageType.richText ||
        type == MessageType.emoji) {
      return false;
    }
    final trimmed = content.trim();
    final lower = trimmed.toLowerCase();
    const markers = {
      '[image]',
      '[audio]',
      '[video]',
      '[file]',
      '[emoji]',
      '[location]',
      '[card]',
      '[system]',
      '[code]',
      '[empty]',
      '[图像]',
      '[图片]',
      '[语音]',
      '[视频]',
      '[文件]',
      '[表情]',
      '[位置]',
      '[卡片]',
      '[代码]',
      '[系统消息]',
      '[系统]',
      '[空内容]',
      'plaintext',
      '[plaintext]',
    };
    if (markers.contains(lower) || markers.contains(trimmed)) return true;
    if (type == MessageType.codeSnippet &&
        trimmed.length >= 3 &&
        trimmed.length <= 20 &&
        RegExp(r'^\[[A-Za-z0-9_+#-]+\]$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }
}
