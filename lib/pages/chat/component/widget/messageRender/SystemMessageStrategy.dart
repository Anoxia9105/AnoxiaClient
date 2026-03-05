import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

/// 系统消息渲染策略
/// 用于渲染各种系统消息，如创建房间、加入房间、离开房间等
class SystemMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: buildSystemctlMessage(message),
    );
  }

  /// 构建系统消息UI
  Widget buildSystemctlMessage(ChatMessage message) {
    // 提取文本样式为常量
    final TextStyle textStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );

    if (message.extra["action"] == null) {
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: "未知系统消息",
        textStyle: textStyle,
        timestamp: message.timestamp,
      );
    }

    final type = message.extra["action"];

    if (type == "ROOM_CREATED_GROUP") {
      final names = message.extra["names"];
      final nickName = message.extra["nickName"];
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedHome03,
        text: "$nickName 邀请了[$names] 加入房间",
        textStyle: textStyle,
        timestamp: message.timestamp,
      );
    }
    if (type == "ROOM_MUTED") {
      final isMute = message.extra["isMute"];
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedHome03,
        text: "管理员 ${isMute ? "[开启全体禁言]" : "[取消全体禁言]"}",
        textStyle: textStyle,
        timestamp: message.timestamp,
      );
    }
    if (type == "USER_KICKED") {
      // final name = message.extra["targetId"];
      final nickName = message.extra["nickName"];
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedUserRemove02,
        text: "$nickName 被管理员踢出了房间",
        textStyle: textStyle,
        timestamp: message.timestamp,
      );
    }

    if (type == "ROOM_CLOSED") {
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedHome03,
        text: "房间已被解散",
        textStyle: textStyle,
        timestamp: message.timestamp,
      );
    }

    return SizedBox.shrink();

    // switch (type) {
    //   case "create":
    //     return _buildMessageRow(
    //       icon: HugeIcons.strokeRoundedHome03,
    //       text: "$name创建了房间",
    //       textStyle: textStyle,
    //     );
    //   case "join":
    //     return _buildMessageRow(
    //       icon: HugeIcons.strokeRoundedUserAdd02,
    //       text: "${(message.extra["operator_name"] ?? "")}邀请[$name]加入了房间",
    //       textStyle: textStyle,
    //     );
    //   case "leave":
    //     return _buildMessageRow(
    //       icon: HugeIcons.strokeRoundedUserRemove02,
    //       text: "$name离开了房间",
    //       textStyle: textStyle,
    //     );
    //   default:
    //     return _buildMessageRow(
    //       icon: HugeIcons.strokeRoundedSettingsError02,
    //       text: "未知系统消息",
    //       textStyle: textStyle,
    //     );
    // }
  }

  /// 构建消息行，统一布局和样式
  Widget _buildMessageRow({
    required dynamic icon,
    required String text,
    required int? timestamp,
    required TextStyle textStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HugeIcon(icon: icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        // 消息主体文本
        Text(text, style: textStyle),
        const SizedBox(width: 8),
        // 时间标签样式
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4), // 圆角
          ),
          child: Text(
            DateUtil.formatTimestampToTime(timestamp),
            style: textStyle.copyWith(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
