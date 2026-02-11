import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/DateUtil.dart';
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
    final isCurrentUser = message.senderId == user?.userId;

    final senderInfo = ref.watch(
      roomMemberServiceProvider.select(
        (map) => (map[message.roomId] ?? []).firstWhere(
          (m) => m.userId == message.senderId,
          orElse: () => ChatRoomMemberVO(nickName: "用户"),
        ),
      ),
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

    /// quill text 需要气泡框
    final bool needsBubble =
        message.messageType == MessageType.quill ||
        message.messageType == MessageType.text &&
            message.payload?.emojiCode == null;

    final strategy = MessageRenderFactory.getStrategy(message.messageType);

    //系统消息 直接渲染
    if (message.messageType == MessageType.system) {
      return strategy.buildContent(context, message, textColor);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // --- 1. 顶部名称与时间层 ---
          _buildHeader(context, isCurrentUser, senderInfo),
          SizedBox(height: 4),

          // --- 2. 头像与消息体层 ---
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            textDirection: isCurrentUser
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: [
              // 头像
              AvatarWidget(
                url: isCurrentUser ? user?.avatar : senderInfo.avatar,
                name: isCurrentUser ? user?.nickName : senderInfo.nickName,
                size: 36, // 适当缩小头像，让比例更协调
              ),

              // 消息气泡
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => Feedback.forLongPress(context),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: needsBubble
                            ? BubbleWidget(
                                // 💡 这里可以根据你的 BubbleWidget 调整箭头位置，使其靠近顶部
                                arrowDirection: isCurrentUser
                                    ? AxisDirection.right
                                    : AxisDirection.left,
                                arrowOffset: 15,
                                // 💡 箭头偏移量减小，使其靠近气泡顶部
                                arrowLength: 6,
                                arrowRadius: 4,
                                arrowWidth: 15,
                                padding: EdgeInsets.symmetric(
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
                                // 稍微圆润一点更精美
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
                    // 💡 发送状态指示器放在气泡下方，显得更简洁
                    if (isCurrentUser)
                      Padding(
                        padding: EdgeInsets.only(top: 2, right: 4),
                        child: _buildStatusIndicator(message),
                      ),
                  ],
                ),
              ),
              // 占位，防止气泡贴边
              SizedBox(width: 20),
              if (isMentionedMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(
                    "@你",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 修改后的 Header：名称加粗，时间变淡
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
      padding: EdgeInsets.symmetric(horizontal: 44), // 避开头像的宽度，对齐气泡起始位
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentUser) ...[
            Text(
              sender.nickName ?? "用户",
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
            Text("  ·  ", style: style),
          ],
          Text(DateUtil.formatTimestampToTime(message.timestamp), style: style),
          if (isCurrentUser) ...[
            Text("  ·  ", style: style),
            Text("我", style: style.copyWith(fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ChatMessage message) {
    switch (message.deliveryStatus) {
      case DeliveryStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.grey),
          ),
        );
      case DeliveryStatus.failed:
        return GestureDetector(
          onTap: () {
            log.info("点击了重发消息: ${message.clientMsgId}");
          },
          child: const Icon(Icons.error, size: 16, color: Colors.red),
        );
      case DeliveryStatus.sent:
        return Icon(
          Icons.check,
          size: 12,
          color: Colors.blue.withValues(alpha: 0.8),
        );
    }
  }
}
