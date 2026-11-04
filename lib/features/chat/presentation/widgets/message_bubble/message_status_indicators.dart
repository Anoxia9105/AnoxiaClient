/// 只展示 @提及、发送中和发送失败；成功发送后不展示回执、不占位。
library;

import 'package:anoxia/framework/provider/chat/room/room_write_access_provider.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'message_resender.dart';

class MessageStatusIndicators extends StatelessWidget {
  const MessageStatusIndicators({
    super.key,
    required this.message,
    required this.isMentionedMe,
    required this.isCurrentUser,
  });
  final ChatMessage message;
  final bool isMentionedMe;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final showDelivery =
        isCurrentUser && message.deliveryStatus != DeliveryStatus.sent;
    if (!isMentionedMe && !showDelivery) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isMentionedMe) const MentionIndicator(),
          if (showDelivery)
            DeliveryStatusIndicator(
              message: message,
              isCurrentUser: isCurrentUser,
            ),
        ],
      ),
    );
  }
}

class MentionIndicator extends StatelessWidget {
  const MentionIndicator({super.key});

  @override
  Widget build(BuildContext context) => Text(
    '@',
    style: Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Theme.of(context).colorScheme.error,
      fontWeight: FontWeight.bold,
    ),
  );
}

class DeliveryStatusIndicator extends ConsumerWidget {
  const DeliveryStatusIndicator({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });
  final ChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isCurrentUser) return const SizedBox.shrink();
    final roomId = message.roomId;
    final canRetry =
        message.deliveryStatus == DeliveryStatus.failed &&
        roomId != null &&
        ref.watch(roomWriteAccessProvider(roomId));
    return switch (message.deliveryStatus) {
      DeliveryStatus.sent => const SizedBox.shrink(),
      DeliveryStatus.sending => const RepaintBoundary(
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      DeliveryStatus.failed => GestureDetector(
        onTap: canRetry
            ? () {
                if (ref.read(roomWriteAccessProvider(roomId))) {
                  MessageResender.resend(ref, message);
                }
              }
            : null,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    };
  }
}
