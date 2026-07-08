/// 用户消息气泡（含头像、昵称、内容、状态指示器）
///
/// 包含完整的用户消息布局组件：
/// - UserMessageBubble：顶层布局，控制整体对齐
/// - MessageHeader：发送者昵称
/// - MessageBubbleRow：内容行（气泡+状态）
/// - MessageContentFrame：内容外壳（包裹气泡或纯内容，含右键菜单）
/// - MessageContent：具体内容（含引用回复支持）
library;

import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/provider/chat/message/reply_jump_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 导入拆分的子组件
import 'bubble_shell.dart';
import 'message_status_indicators.dart';
import 'message_bubble_view_data.dart';

/// 用户消息气泡顶层组件
class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final MessageBubbleViewData view;

  const UserMessageBubble({
    super.key,
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
          MessageHeader(
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
                child: MessageBubbleRow(
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

/// 消息头部（发送者昵称）
class MessageHeader extends StatelessWidget {
  final bool isCurrentUser;
  final String? senderName;

  const MessageHeader({
    super.key,
    required this.isCurrentUser,
    required this.senderName,
  });

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

/// 消息行（气泡内容 + 状态指示器）
class MessageBubbleRow extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final MessageBubbleViewData view;
  final TextDirection direction;

  const MessageBubbleRow({
    super.key,
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
          child: MessageContentFrame(
            message: message,
            strategy: strategy,
            view: view,
          ),
        ),
        MessageStatusIndicators(
          message: message,
          isMentionedMe: view.isMentionedMe,
          isCurrentUser: view.isCurrentUser,
        ),
        SizedBox(width: 20.w), // 留出右侧间距（依赖 screenutil）
      ],
    );
  }
}

/// 消息内容外壳（包裹气泡或纯内容，并附加右键/长按菜单）
class MessageContentFrame extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final MessageBubbleViewData view;

  const MessageContentFrame({
    super.key,
    required this.message,
    required this.strategy,
    required this.view,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = MessageContent(
      message: message,
      strategy: strategy,
      textColor: view.textColor,
    );

    return ChatMessageContextMenu(
      message: message,
      ref: ref,
      child: view.needsBubble
          ? BubbleShell(
              isCurrentUser: view.isCurrentUser,
              backgroundColor: view.bubbleColor,
              child: content,
            )
          : content,
    );
  }
}

/// 消息内容主体（包含引用回复和实际内容）
class MessageContent extends ConsumerWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final Color textColor;

  const MessageContent({
    super.key,
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

  /// 查找被引用的消息
  ChatMessage? _findQuotedMessage(
    WidgetRef ref,
    ChatMessage message,
    String messageId,
  ) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return null;

    final messages = ref.watch(roomMessagesProvider(roomId)).value ?? const [];
    for (final item in messages) {
      if (item.messageId == messageId || item.clientMsgId == messageId) {
        return item;
      }
    }
    return null;
  }

  /// 跳转到引用的消息
  void _jumpToReply(WidgetRef ref, ChatMessage message, String messageId) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return;
    ref
        .read(replyJumpControllerProvider.notifier)
        .jumpTo(roomId: roomId, messageId: messageId);
  }
}
