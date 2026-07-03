import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间详情页滚动到底部按钮组件
///
/// 当消息列表有新消息且用户未在底部时显示，
/// 点击后滚动到消息列表底部
class ChatRoomDetailScrollDownButton extends StatelessWidget {
  /// 点击回调，执行滚动到底部操作
  final VoidCallback onPressed;

  const ChatRoomDetailScrollDownButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary, // 背景使用主题色
        shape: BoxShape.circle, // 容器设为圆形
      ),
      child: IconButton(
        mouseCursor: SystemMouseCursors.click,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          hoverColor: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
        ),
        padding: EdgeInsets.zero, // 确保图标居中
        icon: HugeIcon(
          size: 16,
          icon: HugeIcons.strokeRoundedArrowDown01,
          strokeWidth: 2.0,
          color: theme.colorScheme.onPrimary, // 图标使用主题色之上的文本/图标颜色
        ),
      ),
    );
  }
}
