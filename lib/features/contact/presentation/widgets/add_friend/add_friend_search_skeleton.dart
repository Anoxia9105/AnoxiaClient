import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 添加好友搜索骨架屏
///
/// 搜索过程中显示的用户卡片占位列表
class AddFriendSearchSkeleton extends StatelessWidget {
  const AddFriendSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 46, height: 46, circle: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 180, height: 11),
                    SizedBox(height: 7),
                    SkeletonLine(width: 140, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SkeletonBox(width: 62, height: 30, radius: 14),
            ],
          ),
        );
      },
    );
  }
}
