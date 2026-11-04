// 消息表情回应聚合条 + 候选集
//
// - [reactionEmojiPalette]：悬停和长按表情条用来补足最近记录的默认表情；
// - [MessageReactionBar]：气泡底部的表情、计数和更多回应入口，
//   状态来自 [roomChatReactionsProvider]（WS 广播 + 进房 REST 补拉 + 本地乐观切换），
//   无任何回应数据时整体不占位。
//
// 系统消息（通话/撤回灰条等）不可回应，直接不渲染。
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/chat_reaction_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 表情回应固定候选集（弹窗横向换行展示，服务端仅按 key 幂等存储，无白名单）
///
/// 含 ok（👌）、收到（✅）、合拍（🤝）等聊天常用答复表情
const List<String> reactionEmojiPalette = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

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

/// 气泡底部的表情回应聚合条
class MessageReactionBar extends ConsumerWidget {
  final ChatMessage message;

  const MessageReactionBar({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = message.roomId!;
    final messageId = message.messageId!;
    final board = ref.watch(roomChatReactionsProvider)[roomId];
    final groups = board?.byMessage[messageId];
    if (groups == null || groups.isEmpty) return const SizedBox.shrink();

    // 多个 emoji 稳定排序：计数多的靠前，同计数按 emoji 码序
    var aggregates = groups.values.where((e) => e.count > 0 || e.mine).toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.emoji.compareTo(b.emoji);
      });
    if (aggregates.isEmpty) return const SizedBox.shrink();
    if (aggregates.any(
      (reaction) => reaction.users.entries.any(
        (entry) => entry.value.isEmpty || entry.value == '${entry.key}',
      ),
    )) {
      final members = ref.watch(
        roomMemberServiceProvider.select((state) => state[roomId]),
      );
      final contacts = ref.watch(contactListServiceProvider).value;
      final room = ref.watch(currentRoomProvider(roomId));
      aggregates = [
        for (final reaction in aggregates)
          reaction.copyWith(
            users: reaction.users.map((id, name) {
              if (name.isNotEmpty && name != '$id') return MapEntry(id, name);
              for (final candidate in [
                members?[id]?.nickName,
                contacts?[id]?.nickName,
                if (room?.peerId == id) room?.roomName,
              ]) {
                final displayName = candidate?.trim();
                if (displayName != null && displayName.isNotEmpty) {
                  return MapEntry(id, displayName);
                }
              }
              return MapEntry(id, '$id');
            }),
          ),
      ];
    }

    final colorScheme = Theme.of(context).colorScheme;
    const visibleLimit = 5;
    void toggle(String emoji) {
      ref
          .read(chatMessagesProvider.notifier)
          .toggleReaction(messageId, roomId, emoji);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final aggregate in aggregates.take(visibleLimit))
            Tooltip(
              message: aggregate.users.values.join('、'),
              child: _ReactionChip(
                aggregate: aggregate,
                highlight: aggregate.mine,
                onTap: () => toggle(aggregate.emoji),
                colorScheme: colorScheme,
              ),
            ),
          if (aggregates.length > visibleLimit)
            _MoreReactions(
              reactions: aggregates.skip(visibleLimit).toList(),
              onToggle: toggle,
            ),
        ],
      ),
    );
  }
}

class _MoreReactions extends StatefulWidget {
  const _MoreReactions({required this.reactions, required this.onToggle});

  final List<RoomReactionAggregate> reactions;
  final ValueChanged<String> onToggle;

  @override
  State<_MoreReactions> createState() => _MoreReactionsState();
}

class _MoreReactionsState extends State<_MoreReactions> {
  final _menu = MenuController();
  Timer? _closeTimer;

  void _cancelClose() => _closeTimer?.cancel();

  void _closeSoon() {
    _cancelClose();
    _closeTimer = Timer(const Duration(milliseconds: 220), _menu.close);
  }

  @override
  void dispose() {
    _cancelClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = 'chat_reaction_more_emoji'.tr();
    return MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surfaceContainer,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
        ),
      ),
      menuChildren: [
        MouseRegion(
          onEnter: (_) => _cancelClose(),
          onExit: (_) => _closeSoon(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 248, maxHeight: 240),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  for (final reaction in widget.reactions)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          _ReactionChip(
                            aggregate: reaction,
                            highlight: reaction.mine,
                            onTap: () => widget.onToggle(reaction.emoji),
                            colorScheme: theme.colorScheme,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reaction.users.values.join('、'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => MouseRegion(
        onEnter: (_) {
          _cancelClose();
          if (!controller.isOpen) controller.open();
        },
        onExit: (_) => _closeSoon(),
        child: Semantics(
          label: label,
          button: true,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(RadiusToken.pill),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                _cancelClose();
                if (!controller.isOpen) controller.open();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '+${widget.reactions.length}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
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
