
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:flutter/material.dart';

/// 聊天输入框骨架屏组件
///
/// 用于在聊天输入框加载过程中显示占位内容，
/// 提供与实际输入框相似的视觉结构
class ChatInputSkeleton extends StatelessWidget {
  const ChatInputSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 50, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 18, radius: 9)),
                SizedBox(width: 12),
                SkeletonBox(width: 22, height: 22, circle: true),
                SizedBox(width: 8),
                SkeletonBox(width: 22, height: 22, circle: true),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonLine(width: 120, height: 10),
            ),
          ],
        ),
      ),
    );
  }
}
