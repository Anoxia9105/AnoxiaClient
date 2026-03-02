import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
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

    /// 只有文本消息（非纯表情）和富文本消息才需要气泡，其他类型直接渲染内容即可
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
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // ---  顶部名称与时间层 ---
          _buildHeader(context, isCurrentUser, senderInfo),
          SizedBox(height: 2),

          // ---  头像与消息体层 ---
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
                size: 36,
              ),

              // 消息气泡
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: isCurrentUser
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onLongPress: () => Feedback.forLongPress(context),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: needsBubble
                              ? BubbleWidget(
                                  arrowDirection: isCurrentUser
                                      ? AxisDirection.right
                                      : AxisDirection.left,
                                  arrowOffset: 15,
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
                                  backgroundColor: bubbleBgColor,
                                  contentBuilder: (context) =>
                                      strategy.buildContent(
                                        context,
                                        message,
                                        textColor,
                                      ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: strategy.buildContent(
                                    context,
                                    message,
                                    textColor,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // 3. 状态与 @ 提示（贴底显示）
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMentionedMe)
                            Text(
                              "@你",
                              style: TextStyle(
                                fontSize: 12,
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
            // Text("  ·  ", style: style),
          ],
          // 消息发送时间
          // Text(DateUtil.formatTimestampToTime(message.timestamp), style: style),
          if (isCurrentUser) ...[
            // Text("  ·  ", style: style),
            Text("我", style: style.copyWith(fontWeight: FontWeight.bold)),
          ],
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
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.grey),
          ),
        );
      case DeliveryStatus.failed:
        return GestureDetector(
          onTap: () => _resendMessage(context, ref, message),
          child: const Icon(Icons.error, size: 16, color: Colors.red),
        );
      case DeliveryStatus.sent:
        // return Icon(
        //   Icons.check,
        //   size: 12,
        //   color: Colors.blue.withValues(alpha: 0.8),
        // );
        return SizedBox.shrink(); // 已发送状态不显示任何图标，保持界面简洁
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

    // 1) 将本地消息状态设为 sending
    ref
        .read(chatMessagesProvider.notifier)
        .upsertMessage(
          message.copyWith(deliveryStatus: DeliveryStatus.sending),
        );

    // 2) 构造和发送消息数据（复用服务端 MESSAGE 协议格式）
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

    // 3) 重新启动超时检测（与 _doSend 保持一致的超时逻辑）
    Timer(const Duration(seconds: 10), () {
      ref
          .read(chatMessagesProvider.notifier)
          .handleTimeout(room.roomId!, clientMsgId);
    });
  }
}
