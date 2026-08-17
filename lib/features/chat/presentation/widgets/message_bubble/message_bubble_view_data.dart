/// 消息气泡视图数据聚合类
///
/// 职责：集中计算每个消息所需的所有展示属性（颜色、昵称、头像、是否@我等），
/// 将业务逻辑与 UI 解耦，便于单元测试和复用。
library;

import 'package:anoxia/features/chat/models/chat_message_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';

/// 消息展示视图数据（不可变）
class MessageBubbleViewData {
  final bool isCurrentUser; // 是否当前用户发送
  final bool isMentionedMe; // 是否@了我
  final bool needsBubble; // 是否需要气泡背景（纯文本/富文本/音频需要，纯表情不需要）
  final String? senderName; // 发送者昵称（自己显示“我”，其他显示联系人名称）
  final String? senderAvatar; // 发送者头像URL
  final ChatRoomMemberVO? senderMember; // 发送者在房间中的成员信息（用于点击头像查看资料）
  final Color bubbleColor; // 气泡背景色（自己为primary，对方为surfaceContainerHigh）
  final Color textColor; // 文字颜色（自己为onPrimary，对方为onSurface）
  final double horizontalPadding; // 左右边距（移动端8，桌面端50）

  const MessageBubbleViewData({
    required this.isCurrentUser,
    required this.isMentionedMe,
    required this.needsBubble,
    required this.senderName,
    required this.senderAvatar,
    required this.senderMember,
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
    final senderContact = ref
        .watch(contactListServiceProvider)
        .value?[message.senderId];
    final memberName = senderMember?.nickName?.trim();
    final contactName = senderContact?.remark?.trim().isNotEmpty == true
        ? senderContact!.remark
        : senderContact?.nickName;

    final colorScheme = Theme.of(context).colorScheme;

    // -------- 自己消息：品牌主色 + 对应文字色，天然保证对比度 --------
    final selfBubbleColor = colorScheme.primary;
    final selfTextColor = colorScheme.onPrimary;

    // -------- 对方消息：跟随主题的中性色阶，换肤/切深浅色都能自动适配 --------
    final otherBubbleColor = colorScheme.surfaceContainerHigh;
    final otherTextColor = colorScheme.onSurface;

    final bubbleColor = isCurrentUser ? selfBubbleColor : otherBubbleColor;
    final textColor = isCurrentUser ? selfTextColor : otherTextColor;

    return MessageBubbleViewData(
      isCurrentUser: isCurrentUser,
      isMentionedMe: _isMentionedMe(message, currentUserId, isCurrentUser),
      needsBubble: message.needsBubble,
      senderName: isCurrentUser
          ? user?.nickName
          : _displaySenderName(
              message.senderId,
              memberName?.isNotEmpty == true ? memberName : contactName,
            ),
      senderAvatar: isCurrentUser
          ? user?.avatar
          : ((senderMember?.avatar?.trim().isNotEmpty == true)
                ? senderMember?.avatar
                : senderContact?.avatar),
      senderMember: senderMember,
      bubbleColor: bubbleColor,
      textColor: textColor,
      // UI 布局按宽度断点判定（Web 窄屏等同移动端），而非 isRealMobile()
      horizontalPadding: DeviceUtil.isMobile(context) ? 8 : 50,
    );
  }

  /// 判断当前消息是否@了我（且不是自己发的）
  static bool _isMentionedMe(
    ChatMessage message,
    int? currentUserId,
    bool isCurrentUser,
  ) {
    if (isCurrentUser || currentUserId == null) return false;
    // 群聊 @所有人 视同 @了我
    if (message.payload?.mentionAll == true) return true;
    final mentions = message.payload?.mentions;
    return mentions != null && mentions.contains(currentUserId);
  }

  /// 获取发送者显示名称
  static String _displaySenderName(int? senderId, String? nickName) {
    final name = nickName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (senderId != null) return '用户$senderId';
    return '';
  }
}
