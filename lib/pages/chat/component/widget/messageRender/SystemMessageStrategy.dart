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
      fontSize: 14,
      color: Colors.grey[600],
    );

    // 检查必要字段
    if (message.extra["action"] == null || message.extra["name"] == null) {
      return _buildMessageRow(
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: "未知系统消息",
        textStyle: textStyle,
      );
    }

    final type = message.extra["action"];
    final name = message.extra["name"];

    switch (type) {
      case "create":
        return _buildMessageRow(
          icon: HugeIcons.strokeRoundedHome03,
          text: "$name创建了房间",
          textStyle: textStyle,
        );
      case "join":
        return _buildMessageRow(
          icon: HugeIcons.strokeRoundedUserAdd02,
          text: "$name加入了房间",
          textStyle: textStyle,
        );
      case "leave":
        return _buildMessageRow(
          icon: HugeIcons.strokeRoundedUserRemove02,
          text: "$name离开了房间",
          textStyle: textStyle,
        );
      default:
        return _buildMessageRow(
          icon: HugeIcons.strokeRoundedSettingsError02,
          text: "未知系统消息",
          textStyle: textStyle,
        );
    }
  }

  /// 构建消息行，统一布局和样式
  Widget _buildMessageRow({
    required dynamic icon,
    required String text,
    required TextStyle textStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HugeIcon(icon: icon, size: 16, color: Colors.grey[500]),
        SizedBox(width: 8),
        Text(text, style: textStyle),
      ],
    );
  }
}
