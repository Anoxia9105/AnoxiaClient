import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'dart:async';
import 'dart:convert';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/framework/logs/talker.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((v) => v.value));
    final currentUserId = user?.userId;
    final isCurrentUser = message.senderId == currentUserId;

    final colorScheme = Theme.of(context).colorScheme;

    final bubbleBgColor = isCurrentUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;

    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    final bodyPadding = DeviceUtil.isRealMobile() ? 8.00 : 50.00;

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

    //系统消息 直接渲染
    if (message.messageType == MessageType.system) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: bodyPadding),
        child: strategy.buildContent(context, message, textColor),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: bodyPadding),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isCurrentUser, message.senderName),
          const SizedBox(height: 2),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: isCurrentUser
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: [
              /// Avatar
              AvatarWidget(
                url: isCurrentUser ? user?.avatar : message.senderAvatar,
                name: isCurrentUser ? user?.nickName : message.senderName,
                size: 32,
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
                      child: ChatMessageContextMenu(
                        message: message,
                        ref: ref,
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
                          //太丑了先去掉，后续再优化
                          // Text(
                          //   DateUtil.formatTimestampToTime(message.timestamp),
                          //   style: TextStyle(
                          //     fontSize: 10,
                          //     color: Theme.of(context).colorScheme.outline,
                          //   ),
                          // ),
                          if (isMentionedMe)
                            const Text(
                              '@',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (isCurrentUser)
                            _buildStatusIndicator(context, ref, message),
                        ],
                      ),
                    ),
                    // 右侧留空
                    SizedBox(width: 20.w),
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
    String? sendName,
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
              sendName ?? 'chat_unknown_user'.tr(),
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
          if (isCurrentUser)
            Text(
              'chat_me'.tr(),
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
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
    final messageNotifier = ref.read(chatMessagesProvider.notifier);
    final wsNotifier = ref.read(wsControllerProvider.notifier);
    final room = ref.read(activeRoomProvider);

    if (room == null) {
      log.warning('重发失败：未找到活跃房间');
      return;
    }

    final clientMsgId = message.clientMsgId ?? message.messageId ?? '';

    messageNotifier.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sending),
    );

    final messageData = {
      'topic': 'MESSAGE',
      'data': {
        'messageId': message.messageId ?? clientMsgId,
        'clientMsgId': clientMsgId,
        'roomId': message.roomId ?? room.roomId,
        'targetId': room.peerId,
        'type': message.messageType?.name,
        'payload': message.payload?.toJson(),
        'attachments': message.attachments.map((e) => e.toJson()).toList(),
      },
    };

    log.info('🔁 重发消息: $clientMsgId');

    wsNotifier.sendMessage(jsonEncode(messageData));

    Timer(const Duration(seconds: 10), () {
      messageNotifier.handleTimeout(room.roomId!, clientMsgId);
    });
  }
}
