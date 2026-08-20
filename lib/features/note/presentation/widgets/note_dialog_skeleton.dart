import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 弹窗列表加载骨架屏（替代转圈动画）
///
/// 用于回收站 / 版本历史等弹窗的数据加载占位：
/// 标题行 + 若干列表行的骨架结构。
class NoteDialogListSkeleton extends StatelessWidget {
  const NoteDialogListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 132,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(width: 150, height: 12, radius: 6),
            SizedBox(height: 12),
            SkeletonLine(width: 220, height: 11, radius: 6),
            SizedBox(height: 10),
            SkeletonLine(width: 180, height: 11, radius: 6),
            SizedBox(height: 10),
            SkeletonLine(width: 120, height: 11, radius: 6),
          ],
        ),
      ),
    );
  }
}