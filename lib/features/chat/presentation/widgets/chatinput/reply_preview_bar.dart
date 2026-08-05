/// 回复预览栏组件
///
/// 在聊天输入框上方显示被引用消息的预览条，展示发送者、时间和内容摘要。
/// 支持点击跳转到原消息、清除引用等操作。
import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        borderRadius: BorderRadius.circular(6),
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
              icon: const Icon(Icons.close, size: 16),
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
        borderRadius: BorderRadius.circular(6),
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
    if (senderId != null) return '用户$senderId';
    return '未知用户';
  }

  static String _displayContent(ChatMessage? message) {
    if (message == null) return 'chat_quote_not_found'.tr();

    final payload = message.payload;
    final content = (payload?.content ?? message.content).trim();
    if (content.isNotEmpty) return content;

    return switch (message.messageType) {
      MessageType.image => '[图片]',
      MessageType.audio => '[语音]',
      MessageType.video => '[视频]',
      MessageType.file =>
        payload?.file?.name?.isNotEmpty == true
            ? '[文件] ${payload!.file!.name}'
            : '[文件]',
      MessageType.emoji =>
        payload?.asset?.url?.isNotEmpty == true
            ? '[表情]'
            : payload?.emojiCode?.isNotEmpty == true
            ? payload!.emojiCode!
            : '[表情]',
      MessageType.system => '[系统消息]',
      MessageType.card => '[卡片]',
      MessageType.location => '[位置]',
      MessageType.richText || MessageType.text => '消息',
      null => '消息',
    };
  }
}
