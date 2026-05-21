import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:flutter/material.dart';

/// 聊天房间详情页骨架屏组件
///
/// 用于在消息列表加载过程中显示占位内容，
/// 模拟真实的消息气泡布局，包括：
/// - 左右两侧的消息气泡
/// - 时间分隔条
/// - 用户头像
class ChatRoomDetailSkeleton extends StatelessWidget {
  const ChatRoomDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: 14,
      itemBuilder: (context, index) {
        // 交替显示左右两侧的消息气泡
        final isSelf = index % 2 == 0;
        // 每隔几条消息显示时间分隔条
        final showTime = index % 4 == 0;
        // 根据索引计算不同的气泡尺寸，增加视觉多样性
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
