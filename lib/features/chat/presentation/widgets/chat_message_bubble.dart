import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'dart:async';
import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/RoomMessage.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/framework/logs/talker.dart';

/// 聊天消息气泡组件
///
/// 负责渲染单条聊天消息，包括：
/// - 消息发送者头像和名称
/// - 消息内容气泡（支持文本、图片、文件、富文本等多种类型）
/// - 消息发送状态指示器（发送中、失败、已发送）
/// - @提及提醒
/// - 右键菜单/长按菜单
class ChatMessageBubble extends ConsumerWidget {
  /// 要显示的消息数据
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  int _resolveResendTimeoutSeconds(ChatMessage message) {
    final attachmentCount = message.payload?.mediaAttachments.length ?? 0;
    var timeout = 10 + (attachmentCount * 2);

    if (message.messageType == MessageType.audio ||
        message.messageType == MessageType.file ||
        message.messageType == MessageType.video) {
      timeout += 5;
    }

    return timeout.clamp(10, 30);
  }

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

    /// 某些消息类型需要气泡背景（如文本、富文本），而图片、文件等类型则直接渲染内容，无需气泡
    final bool isSingleEmoji = _isSingleEmojiMessage(message);
    final bool needsBubble =
        message.messageType == MessageType.richText ||
        message.messageType == MessageType.audio ||
        (message.messageType == MessageType.text && !isSingleEmoji);

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

  bool _isSingleEmojiMessage(ChatMessage message) {
    if (message.messageType == MessageType.emoji) return true;
    if (message.payload?.emojiCode != null) return true;
    if (message.messageType != MessageType.text) return false;

    final text = (message.payload?.content ?? message.content).trim();
    if (text.isEmpty) return false;
    final graphemes = text.characters;
    if (graphemes.length != 1) return false;

    final rune = graphemes.first.runes.firstOrNull;
    if (rune == null) return false;

    return rune >= 0x1F000 ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x2300 && rune <= 0x23FF);
  }

  void _resendMessage(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
  ) {
    final messageNotifier = ref.read(chatMessagesProvider.notifier);
    final wsNotifier = ref.read(wsControllerProvider.notifier);

    if (message.roomId == null) {
      log.warning('重发失败：消息缺�?roomId');
      return;
    }

    final clientMsgId = message.clientMsgId ?? message.messageId ?? '';

    messageNotifier.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sending),
    );

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: message.roomId!,
      senderId: message.senderId ?? 0,
      messageType: message.messageType ?? MessageType.text,
      payload: message.payload,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    log.info('🔁 重发消息: $clientMsgId');
    wsNotifier.sendMessage(ImPacketV5.encodeRoomMessageFrame(protoMsg));

    final timeoutSeconds = _resolveResendTimeoutSeconds(message);
    Timer(Duration(seconds: timeoutSeconds), () {
      messageNotifier.handleTimeout(message.roomId!, clientMsgId);
    });
  }
}
