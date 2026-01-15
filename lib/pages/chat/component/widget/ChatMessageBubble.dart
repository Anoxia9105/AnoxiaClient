import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notepadclient/common/widgets/AvatarWidget.dart';
import 'package:notepadclient/framework/domain/ChatMessage.dart';
import 'package:notepadclient/framework/provider/auth/auth_controller.dart';

import '../../../../common/utils/DateUtil.dart';
import '../../../../common/widgets/BubbleDialog.dart';
import '../../../../framework/domain/ChatRoomMemberVO.dart';
import '../../../../framework/protocol/message/RoomMessage.dart';
import '../../../../framework/services/room_member_service.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取当前登录用户
    final user = ref.watch(authControllerProvider.select((v) => v.value));
    final isCurrentUser = message.senderId == user?.userId;

    // 2. 【核心逻辑】获取对方信息
    // 监听 roomMemberServiceProvider，并找到对应的 senderId 成员
    final senderInfo = ref.watch(
      roomMemberServiceProvider.select(
        (map) => (map[message.roomId] ?? []).firstWhere(
          (m) => m.userId == message.senderId,
          orElse: () => ChatRoomMemberVO(nickName: "用户"),
        ),
      ),
    );

    // 主题色适配
    final colorScheme = Theme.of(context).colorScheme;

    //
    // 我方：主色调，对方：浅灰色或容器表面色
    final bubbleBgColor = isCurrentUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;

    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isCurrentUser ? 50 : 12, // 给对方消息留出右边距，我方留出左边距
          right: isCurrentUser ? 12 : 50,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // 头像置顶
          textDirection: isCurrentUser ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // --- 头像区 ---
            AvatarWidget(
              url: isCurrentUser ? user?.avatar : senderInfo.avatar,
              name: isCurrentUser ? user?.nickName : senderInfo.nickName,
            ),

            SizedBox(width: 8),

            // --- 内容区 ---
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // 只有在需要时（如群聊或显示时间）才展示顶部信息
                  _buildHeader(context, isCurrentUser, senderInfo),

                  // 增加点击/长按反馈
                  GestureDetector(
                    onLongPress: () {
                      // TODO: 弹出复制、撤回菜单
                      Feedback.forLongPress(context);
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width *
                            0.65, // 适当放宽最大宽度
                      ),
                      child: BubbleWidget(
                        arrowDirection: isCurrentUser
                            ? AxisDirection.right
                            : AxisDirection.left,
                        arrowOffset: 20,
                        arrowLength: 6,
                        arrowRadius: 3,
                        arrowWidth: 17,
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: bubbleBgColor,
                        contentBuilder: (context) => Text(
                          message.payload?.content ?? '',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 💡 优化 5: 发送状态指示器
                  if (isCurrentUser) _buildStatusIndicator(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建顶部名称和时间
  // --- 修改 Header 逻辑 ---
  Widget _buildHeader(
    BuildContext context,
    bool isCurrentUser,
    ChatRoomMemberVO sender,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h, left: 4.w, right: 4.w),
      child: Text(
        // 如果是对方，显示其昵称；如果是群聊，这种显示很有必要
        "${isCurrentUser ? '' : '${sender.nickName} · '}${DateUtil.formatTimestampToTime(message.timestamp)}",
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  // 构建消息状态（发送中、已送达、已读）
  Widget _buildStatusIndicator(ChatMessage message) {
    // 这里可以根据 message.status 切换不同图标（单钩、双钩、时钟）
    return Padding(
      padding: EdgeInsets.only(top: 2),
      child: Icon(
        Icons.done, // 已读状态
        size: 14,
        color: Colors.blue,
      ),
    );
  }
}
