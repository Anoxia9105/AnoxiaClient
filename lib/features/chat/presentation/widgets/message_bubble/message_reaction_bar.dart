// 消息表情回应聚合条 + 候选集
//
// - [reactionEmojiPalette]：长按菜单/右键菜单点「回应」弹出的固定候选集；
// - [MessageReactionBar]：气泡下方聚合 chips（emoji + 计数，我方高亮），
//   状态来自 [roomChatReactionsProvider]（WS 广播 + 进房 REST 补拉 + 本地乐观切换），
//   无任何回应数据时整体不占位。
//
// 系统消息（通话/撤回灰条等）不可回应，直接不渲染。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/chat_reaction_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 表情回应固定候选集（v1 上线集，服务端仅按 key 幂等存储，无白名单）
const List<String> reactionEmojiPalette = [
  '👍',
  '❤️',
  '😂',
  '😮',
  '😢',
  '🔥',
  '🎉',
  '🙏',
];

/// 该消息是否可回应（气泡聚合条与菜单入口共用条件）
bool canReactToMessage(ChatMessage message) {
  if (message.deliveryStatus != DeliveryStatus.sent) return false;
  final messageId = message.messageId;
  if (messageId == null || messageId.isEmpty) return false;
  final roomId = message.roomId;
  if (roomId == null || roomId.isEmpty) return false;
  if (message.messageType == MessageType.system) return false;
  return true;
}

/// 气泡下方的表情回应聚合条
class MessageReactionBar extends ConsumerWidget {
  final ChatMessage message;

  const MessageReactionBar({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = message.roomId!;
    final messageId = message.messageId!;
    final board = ref.watch(roomChatReactionsProvider)[roomId];
    final groups = board?.byMessage[messageId];
    if (groups == null || groups.isEmpty) return const SizedBox.shrink();

    // 多个 emoji 稳定排序：计数多的靠前，同计数按 emoji 码序
    final aggregates =
        groups.values.where((e) => e.count > 0 || e.mine).toList()
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            if (byCount != 0) return byCount;
            return a.emoji.compareTo(b.emoji);
          });
    if (aggregates.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final aggregate in aggregates)
            _ReactionChip(
              aggregate: aggregate,
              highlight: aggregate.mine,
              onTap: () {
                ref
                    .read(chatMessagesProvider.notifier)
                    .toggleReaction(
                      messageId,
                      roomId,
                      aggregate.emoji,
                    );
              },
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final RoomReactionAggregate aggregate;
  final bool highlight;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ReactionChip({
    required this.aggregate,
    required this.highlight,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = highlight
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(aggregate.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 3),
              Text(
                '${aggregate.count}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
