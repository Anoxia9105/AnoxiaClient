/// 消息状态指示器集合
///
/// 包含：@提及标识、发送状态（发送中/失败/已发送）。
/// 统一管理消息侧边状态展示。
library;

import 'package:anoxia/framework/protocol/message/message_enum.dart';
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
          if (isCurrentUser) DeliveryStatusIndicator(message: message),
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
    return const Text(
      '@',
      style: TextStyle(
        fontSize: 16,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// 发送状态指示器（发送中/失败/已发送）
class DeliveryStatusIndicator extends ConsumerWidget {
  final ChatMessage message;

  const DeliveryStatusIndicator({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (message.deliveryStatus) {
      case DeliveryStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DeliveryStatus.failed:
        return GestureDetector(
          onTap: () => MessageResender.resend(ref, message),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 16, color: Colors.red),
        );
      case DeliveryStatus.sent:
        return const SizedBox.shrink();
    }
  }
}