/// 消息气泡视图数据聚合类
///
/// 职责：集中计算每个消息所需的所有展示属性（颜色、昵称、头像、是否@我等），
/// 将业务逻辑与 UI 解耦，便于单元测试和复用。
library;

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
  final bool isCurrentUser;          // 是否当前用户发送
  final bool isMentionedMe;          // 是否@了我
  final bool needsBubble;            // 是否需要气泡背景（纯文本/富文本/音频需要，纯表情不需要）
  final String? senderName;          // 发送者昵称（自己显示“我”，其他显示联系人名称）
  final String? senderAvatar;        // 发送者头像URL
  final Color bubbleColor;           // 气泡背景色（自己为primary，对方为surfaceContainerHigh）
  final Color textColor;             // 文字颜色（自己为onPrimary，对方为onSurfaceVariant）
  final double horizontalPadding;    // 左右边距（移动端8，桌面端50）

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
    final bubbleColor = isCurrentUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return MessageBubbleViewData(
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

  /// 判断消息是否需要气泡背景
  static bool _needsBubble(ChatMessage message) {
    return message.messageType == MessageType.richText ||
        message.messageType == MessageType.audio ||
        (message.messageType == MessageType.text && !_isSingleEmoji(message));
  }

  /// 判断是否为单个表情（纯表情消息不需要气泡）
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

  /// 获取发送者显示名称
  static String _displaySenderName(int? senderId, String? nickName) {
    final name = nickName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (senderId != null) return '用户$senderId';
    return '';
  }
}