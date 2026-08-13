import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class BackgroundVideoThumbnail extends StatelessWidget {
  const BackgroundVideoThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x99000000),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(7),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPlay,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
