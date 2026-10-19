/// 消息状态指示器集合
///
/// 包含：@提及标识、发送状态（发送中/失败/已发送/已送达/已读）。
/// 统一管理消息侧边状态展示。
library;

import 'package:anoxia/common/utils/peer_read_receipt.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'message_resender.dart';

/// 消息状态指示器（组合 @标识 和 发送状态）
class MessageStatusIndicators extends ConsumerWidget {
  final ChatMessage message;
  final bool isMentionedMe;
  final bool isCurrentUser;

  const MessageStatusIndicators({
    super.key,
    required this.message,
    required this.isMentionedMe,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isMentionedMe) const MentionIndicator(),
          if (isCurrentUser)
            DeliveryStatusIndicator(
              message: message,
              isCurrentUser: isCurrentUser,
            ),
        ],
      ),
    );
  }
}

/// @提及指示器（红色 @ 符号）
class MentionIndicator extends StatelessWidget {
  const MentionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '@',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// 发送状态指示器（发送中/失败/已发送/单聊已读/已送达）
class DeliveryStatusIndicator extends ConsumerWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const DeliveryStatusIndicator({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (message.deliveryStatus) {
      case DeliveryStatus.sending:
        // 进度圈是无限动画，用 RepaintBoundary 隔离，避免持续重绘整条消息
        // （含头像）触发 Web/Wasm 下的头像闪烁。
        return const RepaintBoundary(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case DeliveryStatus.failed:
        return GestureDetector(
          onTap: () => MessageResender.resend(ref, message),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        );
      case DeliveryStatus.sent:
        // P0-2：单聊下「已读 / 已送达」展示（纯函数判定，群聊/AI 返回 none）。
        return _SentReadStateLabel(
          message: message,
          isCurrentUser: isCurrentUser,
        );
    }
  }
}

/// 已 ACK（sent）消息的回执态标签。
///
/// 数据链路：`currentRoomProvider`（单聊判定 + 对端 userId）→
/// `roomMemberProvider`（成员缓存行，含服务端 read_seq 快照）→
/// `evaluatePeerReadIndicator` 纯函数。任一环节不可用（房间已退/未拉到
/// 成员）都安全降级为「已送达」，不抛错也不闪占位。
class _SentReadStateLabel extends ConsumerWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const _SentReadStateLabel({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String roomId = message.roomId ?? '';
    if (roomId.isEmpty) return const SizedBox.shrink();

    final room = ref.watch(currentRoomProvider(roomId));
    final isSingleChat = room?.roomType == RoomType.singleChat.index;
    final int? peerId = room?.peerId;
    // 对端成员行；未拉到成员时保持 null，展示层自动走「已送达」降级
    final member = (peerId == null)
        ? null
        : ref.watch(roomMemberProvider((roomId, peerId)));

    final indicator = evaluatePeerReadIndicator(
      isMine: isCurrentUser,
      deliveryStatus: message.deliveryStatus,
      isSingleChat: isSingleChat,
      messageSeq: message.seq,
      peerReadSeq: member?.lastReadSeq,
    );

    return switch (indicator) {
      PeerReadIndicator.none => const SizedBox.shrink(),
      PeerReadIndicator.read => _StateLabel(
        text: 'chat_read'.tr(),
        color: Theme.of(context).colorScheme.primary,
      ),
      PeerReadIndicator.delivered => _StateLabel(
        text: 'chat_delivered'.tr(),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };
  }
}

/// 侧边小字标签（无动效，遵循减少动效设置）
class _StateLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _StateLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
