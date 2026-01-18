import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/DateUtil.dart';
import '../../../../common/widgets/BubbleDialog.dart';
import '../../../../framework/domain/ChatRoomMemberVO.dart';
import '../../../../framework/services/room_member_service.dart';
import 'messageRender/MessageRenderFactory.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //TODO 系统消息 直接渲染

    final user = ref.watch(authControllerProvider.select((v) => v.value));
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

    /// quill text 需要气泡框
    final bool needsBubble =
        message.messageType == MessageType.quill ||
        message.messageType == MessageType.text;

    final strategy = MessageRenderFactory.getStrategy(message.messageType);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        // 💡 整个消息体（含名称时间）的对齐
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
            crossAxisAlignment: CrossAxisAlignment.start, // 💡 确保头像和气泡顶部对齐
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

              SizedBox(width: 8),

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
              SizedBox(width: 40),
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
      padding: EdgeInsets.symmetric(horizontal: 44), // 💡 避开头像的宽度，对齐气泡起始位
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
    return Icon(
      Icons.done_all, // 使用双钩代表送达/已读
      size: 12,
      color: Colors.blue.withOpacity(0.8),
    );
  }
}
