import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReplyPreviewBar extends ConsumerWidget {
  final ChatMessage? message;
  final String? fallbackMessageId;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool dense;

  const ReplyPreviewBar({
    super.key,
    required this.message,
    this.fallbackMessageId,
    this.onClear,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sender = _displaySender(ref, message);
    final time = DateUtil.formatTimestampToTime(message?.timestamp);
    final content = _displayContent(message, fallbackMessageId);

    final bar = Container(
      width: double.infinity,
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
          Expanded(
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
              tooltip: '取消引用',
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: bar,
      ),
    );
  }

  static String _displaySender(WidgetRef ref, ChatMessage? message) {
    if (message == null) return '引用消息';

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

  static String _displayContent(ChatMessage? message, String? fallbackId) {
    if (message == null) {
      if (fallbackId == null || fallbackId.isEmpty) return '引用消息';
      return '引用消息 $fallbackId';
    }

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
        payload?.emojiCode?.isNotEmpty == true ? payload!.emojiCode! : '[表情]',
      MessageType.system => '[系统消息]',
      MessageType.card => '[卡片]',
      MessageType.location => '[位置]',
      MessageType.richText || MessageType.text => '消息',
      null => '消息',
    };
  }
}
