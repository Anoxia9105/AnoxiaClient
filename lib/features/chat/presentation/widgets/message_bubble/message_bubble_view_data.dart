/// 消息气泡视图数据聚合类
///
/// 职责：集中计算每个消息所需的所有展示属性（颜色、昵称、头像、是否@我等），
/// 将业务逻辑与 UI 解耦，便于单元测试和复用。
library;

import 'package:anoxia/features/chat/models/chat_message_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';

/// 消息展示视图数据（不可变）
class MessageBubbleViewData {
  final bool isCurrentUser; // 是否当前用户发送
  final bool isMentionedMe; // 是否@了我
  final bool needsBubble; // 是否需要气泡背景（纯文本/富文本/音频需要，纯表情不需要）
  final String? senderName; // 发送者昵称（自己显示“我”，其他显示联系人名称）
  final String? senderAvatar; // 发送者头像URL
  final Color bubbleColor; // 气泡背景色（自己为primary，对方为surfaceContainerHigh）
  final Color textColor; // 文字颜色（自己为onPrimary，对方为onSurfaceVariant）
  final double horizontalPadding; // 左右边距（移动端8，桌面端50）

  const MessageBubbleViewData({
    required this.isCurrentUser,
    required this.isMentionedMe,
    required this.needsBubble,
    required this.senderName,
    required this.senderAvatar,
    required this.bubbleColor,
    required this.textColor,
    required this.horizontalPadding,
  });

  /// 从上下文和 Ref 中解析出完整的视图数据
  static MessageBubbleViewData resolve(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
  ) {
    // 获取当前登录用户
    final user = ref.watch(
      authControllerProvider.select((value) => value.value),
    );
    final currentUserId = user?.userId;
    final isCurrentUser = message.senderId == currentUserId;

    // 获取房间成员列表（用于显示发送者昵称）
    final roomMembers = message.roomId?.isNotEmpty == true
        ? ref.watch(roomMembersProvider(message.roomId!))
        : const <ChatRoomMemberVO>[];
    final senderMember = roomMembers
        .where((member) => member.userId == message.senderId)
        .firstOrNull;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // -------- 自己消息：使用品牌主色，但保证文字对比度 --------
    final selfBubbleColor = colorScheme.primary; // 固定主色
    final selfTextColor = colorScheme.onPrimary; // 主色上的文字（通常白色）

    // -------- 对方消息：使用中性色，不依赖主题主色 --------
    final otherBubbleColor = isDark
        ? const Color(0xFF2C2C2C) // 暗色模式：深灰
        : const Color(0xFFE8E8E8); // 亮色模式：浅灰

    final otherTextColor = isDark ? Colors.white : Colors.black87;

    final bubbleColor = isCurrentUser ? selfBubbleColor : otherBubbleColor;
    final textColor = isCurrentUser ? selfTextColor : otherTextColor;

    return MessageBubbleViewData(
      isCurrentUser: isCurrentUser,
      isMentionedMe: _isMentionedMe(message, currentUserId, isCurrentUser),
      needsBubble: message.needsBubble,
      senderName: isCurrentUser
          ? user?.nickName
          : _displaySenderName(message.senderId, senderMember?.nickName),
      senderAvatar: isCurrentUser ? user?.avatar : senderMember?.avatar,
      bubbleColor: bubbleColor,
      textColor: textColor,
      horizontalPadding: DeviceUtil.isRealMobile() ? 8 : 50,
    );
  }

  /// 判断当前消息是否@了我（且不是自己发的）
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

  /// 获取发送者显示名称
  static String _displaySenderName(int? senderId, String? nickName) {
    final name = nickName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (senderId != null) return '用户$senderId';
    return '';
  }
}
