import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:flutter/material.dart';

class ChatRoomListItemSkeleton extends StatelessWidget {
  final int index;

  const ChatRoomListItemSkeleton({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final titleWidth = 82.0 + (index % 3) * 26;
    final subtitleWidth = 130.0 + (index % 4) * 28;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          const Stack(
            clipBehavior: Clip.none,
            children: [
              SkeletonBox(width: 40, height: 40, radius: 8),
              Positioned(
                right: -1,
                bottom: -1,
                child: SkeletonBox(width: 11, height: 11, circle: true),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: titleWidth, height: 13),
                const SizedBox(height: 9),
                SkeletonLine(width: subtitleWidth, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLine(width: 38, height: 10),
              SizedBox(height: 10),
              SkeletonBox(width: 12, height: 12, circle: true),
            ],
          ),
        ],
      ),
    );
  }
}
