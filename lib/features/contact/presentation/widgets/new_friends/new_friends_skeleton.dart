import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 新好友请求骨架屏
///
/// 加载好友请求列表时显示的占位内容
class NewFriendsSkeleton extends StatelessWidget {
  const NewFriendsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 6),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final nickWidth = 75.0 + (index % 4) * 18;
        final remarkWidth = 140.0 + (index % 3) * 26;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 40, height: 40, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: nickWidth, height: 14),
                    const SizedBox(height: 8),
                    SkeletonLine(width: remarkWidth, height: 11),
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 110, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              index.isEven
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkeletonBox(width: 28, height: 28, circle: true),
                        SizedBox(width: 8),
                        SkeletonBox(width: 28, height: 28, circle: true),
                      ],
                    )
                  : const SkeletonBox(width: 58, height: 26, radius: 14),
            ],
          ),
        );
      },
    );
  }
}
