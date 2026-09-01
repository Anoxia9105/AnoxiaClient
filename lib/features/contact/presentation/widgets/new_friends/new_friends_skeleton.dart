import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 新好友请求骨架屏
///
/// 加载好友请求列表时显示的占位内容，与卡片式列表布局一致。
class NewFriendsSkeleton extends StatelessWidget {
  const NewFriendsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final nickWidth = 90.0 + (index % 4) * 16;
        final remarkWidth = 160.0 + (index % 3) * 24;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SkeletonBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonLine(width: nickWidth, height: 13),
                        const Spacer(),
                        const SkeletonLine(width: 52, height: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SkeletonLine(width: remarkWidth, height: 11),
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 120, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              index.isEven
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkeletonBox(width: 62, height: 30, radius: 15),
                        SizedBox(width: 8),
                        SkeletonBox(width: 62, height: 30, radius: 15),
                      ],
                    )
                  : const SkeletonBox(width: 66, height: 26, radius: 13),
            ],
          ),
        );
      },
    );
  }
}
