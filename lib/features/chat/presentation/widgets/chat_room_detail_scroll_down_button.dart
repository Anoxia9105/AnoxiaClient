import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatRoomDetailScrollDownButton extends StatelessWidget {
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
