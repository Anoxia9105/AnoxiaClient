import 'dart:async';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';
import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/RoomMessage.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/reply_jump_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Single chat message entry.
///
/// This widget keeps orchestration thin and delegates layout, content, status,
/// and resend behavior to smaller private components below.
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategy = MessageRenderFactory.getStrategy(message.messageType);
    final view = _MessageBubbleViewData.resolve(context, ref, message);

    if (message.messageType == MessageType.system) {
      return _SystemMessageBubble(
        message: message,
        strategy: strategy,
        textColor: view.textColor,
        horizontalPadding: view.horizontalPadding,
      );
    }

    return _UserMessageBubble(message: message, strategy: strategy, view: view);
  }
}

class _MessageBubbleViewData {
  final bool isCurrentUser;
  final bool isMentionedMe;
  final bool needsBubble;
  final String? senderName;
  final String? senderAvatar;
  final Color bubbleColor;
  final Color textColor;
  final double horizontalPadding;

  const _MessageBubbleViewData({
    required this.isCurrentUser,
    required this.isMentionedMe,
    required this.needsBubble,
    required this.senderName,
    required this.senderAvatar,
    required this.bubbleColor,
    required this.textColor,
    required this.horizontalPadding,
  });

  static _MessageBubbleViewData resolve(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
  ) {
    final user = ref.watch(
      authControllerProvider.select((value) => value.value),
    );
    final currentUserId = user?.userId;
    final isCurrentUser = message.senderId == currentUserId;
    final roomMembers = message.roomId?.isNotEmpty == true
        ? ref.watch(roomMembersProvider(message.roomId!))
        : const [];
    final senderMember = roomMembers
        .where((member) => member.userId == message.senderId)
        .firstOrNull;

    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = isCurrentUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return _MessageBubbleViewData(
      isCurrentUser: isCurrentUser,
      isMentionedMe: _isMentionedMe(message, currentUserId, isCurrentUser),
      needsBubble: _needsBubble(message),
      senderName: isCurrentUser
          ? user?.nickName
          : _displaySenderName(message.senderId, senderMember?.nickName),
      senderAvatar: isCurrentUser ? user?.avatar : senderMember?.avatar,
      bubbleColor: bubbleColor,
      textColor: textColor,
      horizontalPadding: DeviceUtil.isRealMobile() ? 8 : 50,
    );
  }

  static bool _isMentionedMe(
    ChatMessage message,
    int? currentUserId,
    bool isCurrentUser,
  ) {
    final mentions = message.payload?.mentions;
    return mentions != null &&
        !isCurrentUser &&
        currentUserId != null &&
        mentions.contains(currentUserId);
  }

  static bool _needsBubble(ChatMessage message) {
    return message.messageType == MessageType.richText ||
        message.messageType == MessageType.audio ||
        (message.messageType == MessageType.text && !_isSingleEmoji(message));
  }

  static bool _isSingleEmoji(ChatMessage message) {
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

  static String _displaySenderName(int? senderId, String? nickName) {
    final name = nickName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (senderId != null) return '用户$senderId';
    return '';
  }
}

class _SystemMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final Color textColor;
  final double horizontalPadding;

  const _SystemMessageBubble({
    required this.message,
    required this.strategy,
    required this.textColor,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: horizontalPadding),
      child: strategy.buildContent(context, message, textColor),
    );
  }
}

class _UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final _MessageBubbleViewData view;

  const _UserMessageBubble({
    required this.message,
    required this.strategy,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final direction = view.isCurrentUser
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: view.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: view.isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _MessageHeader(
            isCurrentUser: view.isCurrentUser,
            senderName: view.senderName,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: direction,
            children: [
              AvatarWidget(
                url: view.senderAvatar,
                name: view.senderName,
                size: 32,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: _MessageBubbleRow(
                  message: message,
                  strategy: strategy,
                  view: view,
                  direction: direction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  final bool isCurrentUser;
  final String? senderName;

  const _MessageHeader({required this.isCurrentUser, required this.senderName});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Text(
        isCurrentUser ? 'chat_me'.tr() : senderName ?? 'chat_unknown_user'.tr(),
        style: style,
      ),
    );
  }
}

class _MessageBubbleRow extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final _MessageBubbleViewData view;
  final TextDirection direction;

  const _MessageBubbleRow({
    required this.message,
    required this.strategy,
    required this.view,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      textDirection: direction,
      children: [
        Flexible(
          child: _MessageContentFrame(
            message: message,
            strategy: strategy,
            view: view,
          ),
        ),
        _MessageSideStatus(message: message, view: view),
        SizedBox(width: 20.w),
      ],
    );
  }
}

class _MessageContentFrame extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final _MessageBubbleViewData view;

  const _MessageContentFrame({
    required this.message,
    required this.strategy,
    required this.view,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _MessageContent(
      message: message,
      strategy: strategy,
      textColor: view.textColor,
    );

    return ChatMessageContextMenu(
      message: message,
      ref: ref,
      child: view.needsBubble
          ? _BubbleShell(
              isCurrentUser: view.isCurrentUser,
              backgroundColor: view.bubbleColor,
              child: content,
            )
          : content,
    );
  }
}

class _BubbleShell extends StatelessWidget {
  final bool isCurrentUser;
  final Color backgroundColor;
  final Widget child;

  const _BubbleShell({
    required this.isCurrentUser,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BubbleWidget(
      arrowDirection: isCurrentUser ? AxisDirection.right : AxisDirection.left,
      arrowOffset: 15,
      arrowLength: 6,
      arrowRadius: 4,
      arrowWidth: 15,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      border: BorderSide(
        width: 1,
        color: colorScheme.surface.withValues(alpha: 0.5),
      ),
      borderRadius: BorderRadius.circular(4),
      backgroundColor: backgroundColor,
      contentBuilder: (_) => child,
    );
  }
}

class _MessageContent extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final Color textColor;

  const _MessageContent({
    required this.message,
    required this.strategy,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = strategy.buildContent(context, message, textColor);
    final replyTo = message.payload?.replyTo;
    if (replyTo == null || replyTo.isEmpty) return body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReplyPreviewBar(
          message: _findQuotedMessage(ref, message, replyTo),
          fallbackMessageId: replyTo,
          dense: true,
          onTap: () => _jumpToReply(ref, message, replyTo),
        ),
        const SizedBox(height: 6),
        body,
      ],
    );
  }

  ChatMessage? _findQuotedMessage(
    WidgetRef ref,
    ChatMessage message,
    String messageId,
  ) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return null;

    final messages = ref.watch(
      chatMessagesProvider.select((state) => state[roomId] ?? const []),
    );
    for (final item in messages) {
      if (item.messageId == messageId || item.clientMsgId == messageId) {
        return item;
      }
    }
    return null;
  }

  void _jumpToReply(WidgetRef ref, ChatMessage message, String messageId) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return;
    ref
        .read(replyJumpControllerProvider.notifier)
        .jumpTo(roomId: roomId, messageId: messageId);
  }
}

class _MessageSideStatus extends ConsumerWidget {
  final ChatMessage message;
  final _MessageBubbleViewData view;

  const _MessageSideStatus({required this.message, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (view.isMentionedMe) const _MentionIndicator(),
          if (view.isCurrentUser) _DeliveryStatusIndicator(message: message),
        ],
      ),
    );
  }
}

class _MentionIndicator extends StatelessWidget {
  const _MentionIndicator();

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

class _DeliveryStatusIndicator extends ConsumerWidget {
  final ChatMessage message;

  const _DeliveryStatusIndicator({required this.message});

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
          onTap: () => _MessageResender.resend(ref, message),
          child: const Icon(Icons.error, size: 16, color: Colors.red),
        );
      case DeliveryStatus.sent:
        return const SizedBox.shrink();
    }
  }
}

class _MessageResender {
  const _MessageResender._();

  static void resend(WidgetRef ref, ChatMessage message) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) {
      log.warning('重发失败：消息缺少 roomId');
      return;
    }

    final messageNotifier = ref.read(chatMessagesProvider.notifier);
    final wsNotifier = ref.read(wsControllerProvider.notifier);
    final clientMsgId = message.clientMsgId ?? message.messageId ?? '';

    messageNotifier.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sending),
    );

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: message.senderId ?? 0,
      messageType: message.messageType ?? MessageType.text,
      payload: message.payload,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    log.info('重发消息: $clientMsgId');
    wsNotifier.sendMessage(ImPacketV5.encodeRoomMessageFrame(protoMsg));

    Timer(Duration(seconds: _resendTimeoutSeconds(message)), () {
      messageNotifier.handleTimeout(roomId, clientMsgId);
    });
  }

  static int _resendTimeoutSeconds(ChatMessage message) {
    final attachmentCount = message.payload?.mediaAttachments.length ?? 0;
    var timeout = 10 + (attachmentCount * 2);

    if (message.messageType == MessageType.audio ||
        message.messageType == MessageType.file ||
        message.messageType == MessageType.video) {
      timeout += 5;
    }

    return timeout.clamp(10, 30);
  }
}
