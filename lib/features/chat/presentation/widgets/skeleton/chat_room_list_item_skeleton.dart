import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:flutter/material.dart';

/// 聊天房间列表项骨架屏组件
///
/// 用于在房间列表项加载过程中显示占位内容，
/// 模拟真实的房间列表项布局，包括：
/// - 房间头像
/// - 房间名称
/// - 最后消息预览
/// - 时间戳
/// - 未读数角标
class ChatRoomListItemSkeleton extends StatelessWidget {
  /// 列表项索引，用于生成不同尺寸的占位内容
  final int index;

  const ChatRoomListItemSkeleton({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // 根据索引计算不同的占位尺寸，增加视觉多样性
    final titleWidth = 82.0 + (index % 3) * 26;
    final subtitleWidth = 130.0 + (index % 4) * 28;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          // 头像和在线状态角标
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
          // 房间名称和消息预览
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
          // 时间戳和未读数角标
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
