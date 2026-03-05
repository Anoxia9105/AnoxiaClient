import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';

import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/widgets/BubbleDialog.dart';
import '../../../../framework/domain/ChatRoomMemberVO.dart';
import '../../../../framework/logs/talker.dart';
import '../../../../framework/provider/chat/room/room_member_service.dart';
import 'messageRender/MessageRenderFactory.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((v) => v.value));
    final currentUserId = user?.userId;
    final isCurrentUser = message.senderId == currentUserId;

    final senderInfo = ref.watch(
      roomMemberServiceProvider.select((map) {
        if (message.roomId == null || message.senderId == null) {
          return ChatRoomMemberVO(nickName: "--");
        }

        final memberList = map[message.roomId];
        if (memberList == null || memberList.isEmpty) {
          return ChatRoomMemberVO(nickName: "--");
        }

        final sender = memberList.firstWhereOrNull(
          (m) => m.userId == message.senderId,
        );

        return sender ?? ChatRoomMemberVO(nickName: "--");
      }),
    );

    final colorScheme = Theme.of(context).colorScheme;

    final bubbleBgColor = isCurrentUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;

    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    final mentionList = message.payload?.mentions;
    bool isMentionedMe = false;

    if (mentionList != null &&
        !isCurrentUser &&
        currentUserId != null &&
        mentionList.contains(currentUserId)) {
      isMentionedMe = true;
    }

    final bool needsBubble =
        message.messageType == MessageType.quill ||
        message.messageType == MessageType.text &&
            message.payload?.emojiCode == null;

    final strategy = MessageRenderFactory.getStrategy(message.messageType);

    if (message.messageType == MessageType.system) {
      return strategy.buildContent(context, message, textColor);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 50),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isCurrentUser, senderInfo),
          const SizedBox(height: 2),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: isCurrentUser
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: [
              /// Avatar
              AvatarWidget(
                url: isCurrentUser ? user?.avatar : senderInfo.avatar,
                name: isCurrentUser ? user?.nickName : senderInfo.nickName,
                size: 36,
              ),

              const SizedBox(width: 6),

              /// Message
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: isCurrentUser
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    /// Bubble
                    Flexible(
                      child: GestureDetector(
                        onLongPress: () => Feedback.forLongPress(context),
                        child: needsBubble
                            ? BubbleWidget(
                                arrowDirection: isCurrentUser
                                    ? AxisDirection.right
                                    : AxisDirection.left,
                                arrowOffset: 15,
                                arrowLength: 6,
                                arrowRadius: 4,
                                arrowWidth: 15,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                border: BorderSide(
                                  width: 1,
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(4),
                                backgroundColor: bubbleBgColor,
                                contentBuilder: (context) => strategy
                                    .buildContent(context, message, textColor),
                              )
                            : strategy.buildContent(
                                context,
                                message,
                                textColor,
                              ),
                      ),
                    ),

                    /// status
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMentionedMe)
                            const Text(
                              "@你",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (isCurrentUser)
                            _buildStatusIndicator(context, ref, message),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isCurrentUser,
    ChatRoomMemberVO sender,
  ) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentUser)
            Text(
              sender.nickName ?? "用户",
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
          if (isCurrentUser)
            Text("我", style: style.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
  ) {
    switch (message.deliveryStatus) {
      case DeliveryStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case DeliveryStatus.failed:
        return GestureDetector(
          onTap: () => _resendMessage(context, ref, message),
          child: const Icon(Icons.error, size: 16, color: Colors.red),
        );

      case DeliveryStatus.sent:
        return const SizedBox.shrink();
    }
  }

  void _resendMessage(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
  ) {
    final room = ref.read(activeRoomProvider);

    if (room == null) {
      log.warning('重发失败：未找到活跃房间');
      return;
    }

    final clientMsgId = message.clientMsgId ?? message.messageId ?? '';

    ref
        .read(chatMessagesProvider.notifier)
        .upsertMessage(
          message.copyWith(deliveryStatus: DeliveryStatus.sending),
        );

    final messageData = {
      "topic": "MESSAGE",
      "data": {
        "messageId": message.messageId ?? clientMsgId,
        "clientMsgId": clientMsgId,
        "roomId": message.roomId ?? room.roomId,
        "targetId": room.peerId,
        "type": message.messageType?.name,
        "payload": message.payload?.toJson(),
        "attachments": message.attachments.map((e) => e.toJson()).toList(),
      },
    };

    log.info("🔁 重发消息: $clientMsgId");

    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(jsonEncode(messageData));

    Timer(const Duration(seconds: 10), () {
      ref
          .read(chatMessagesProvider.notifier)
          .handleTimeout(room.roomId!, clientMsgId);
    });
  }
}
