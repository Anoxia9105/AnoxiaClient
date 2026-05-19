import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:flutter/material.dart';

/// 聊天房间详情页面骨架屏
///
/// 用于在消息加载过程中显示占位内容
class ChatRoomDetailSkeleton extends StatelessWidget {
  const ChatRoomDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: 14,
      itemBuilder: (context, index) {
        final isSelf = index % 2 == 0;
        final showTime = index % 4 == 0;
        final bubbleWidth = isSelf
            ? 120.0 + (index % 3) * 34
            : 150.0 + (index % 3) * 42;
        final bubbleHeight = 34.0 + (index % 3) * 12;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              if (showTime)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SkeletonLine(width: 84, height: 11),
                ),
              Row(
                mainAxisAlignment: isSelf
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isSelf) ...[
                    const SkeletonBox(width: 30, height: 30, circle: true),
                    const SizedBox(width: 8),
                  ],
                  SkeletonBox(
                    width: bubbleWidth,
                    height: bubbleHeight,
                    radius: 14,
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 8),
                    const SkeletonBox(width: 30, height: 30, circle: true),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
