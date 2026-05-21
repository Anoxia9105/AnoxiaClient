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
    return SizedBox(
      width: 35,
      height: 35,
      child: IconButton(
        onPressed: onPressed,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedCircleArrowDown02,
          strokeWidth: 2.0,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
