import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/widgets/app/background_video_view.dart';

class BackgroundVideoThumbnail extends StatelessWidget {
  final String url;

  const BackgroundVideoThumbnail({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        BackgroundVideoView(
          key: ValueKey(url),
          url: url,
          autoplay: false,
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
