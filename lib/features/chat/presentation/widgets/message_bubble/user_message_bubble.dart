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

import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/chat/message/reply_jump_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';

// 导入拆分的子组件
import 'bubble_shell.dart';
import 'message_status_indicators.dart';
import 'message_bubble_view_data.dart';

/// 用户消息气泡顶层组件
class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final MessageBubbleViewData view;
  final ChatMessageLayout layout;
  final VoidCallback? onAvatarTap;

  const UserMessageBubble({
    super.key,
    required this.message,
    required this.strategy,
    required this.view,
    required this.layout,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final direction = layout.placeOnLeft
        ? TextDirection.ltr
        : TextDirection.rtl;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: layout.verticalMargin,
        horizontal: layout.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: layout.placeOnLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          MessageHeader(
            isCurrentUser: view.isCurrentUser,
            senderName: view.senderName,
            horizontalInset: layout.headerInset,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: direction,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAvatarTap,
                child: AvatarWidget(
                  url: view.senderAvatar,
                  name: view.senderName,
                  size: layout.avatarSize,
                ),
              ),
              SizedBox(width: layout.avatarGap),
              Flexible(
                child: MessageBubbleRow(
                  message: message,
                  strategy: strategy,
                  view: view,
                  direction: direction,
                  trailingSpace: layout.trailingSpace,
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
  final double horizontalInset;

  const MessageHeader({
    super.key,
    required this.isCurrentUser,
    required this.senderName,
    required this.horizontalInset,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
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
  final double trailingSpace;

  const MessageBubbleRow({
    super.key,
    required this.message,
    required this.strategy,
    required this.view,
    required this.direction,
    required this.trailingSpace,
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
        SizedBox(width: trailingSpace),
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

    final roomId = message.roomId;
    final quotedLookup = (roomId == null || roomId.isEmpty)
        ? const AsyncValue<ChatMessage?>.data(null)
        : ref.watch(
            quotedMessageLookupProvider((roomId: roomId, messageId: replyTo)),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReplyPreviewBar(
          message: quotedLookup.value,
          dense: true,
          onTap: () => _jumpToReply(ref, message, replyTo, quotedLookup),
        ),
        const SizedBox(height: 6),
        body,
      ],
    );
  }

  /// 跳转到引用的消息；已确认被引用消息不存在（已撤回/删除）时直接提示，
  /// 不再触发无意义的补拉历史。
  void _jumpToReply(
    WidgetRef ref,
    ChatMessage message,
    String messageId,
    AsyncValue<ChatMessage?> quotedLookup,
  ) {
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return;
    if (quotedLookup.hasValue && quotedLookup.value == null) {
      Toast.showToast('chat_quote_not_found'.tr(), type: ToastType.error);
      return;
    }
    ref
        .read(replyJumpControllerProvider.notifier)
        .jumpTo(roomId: roomId, messageId: messageId);
  }
}
