import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 记事本编辑器骨架屏
///
/// 切换笔记时右侧编辑区的加载占位：模拟标题行、工具栏按钮组、
/// 正文段落与底部状态条，避免请求期间右侧区域毫无反馈、观感像卡顿。
class NoteEditorSkeleton extends StatelessWidget {
  const NoteEditorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行占位：标题输入框 + 标签按钮
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: SkeletonBox(
                  width: double.infinity,
                  height: 24,
                  radius: 8,
                ),
              ),
              SizedBox(width: 4),
              SkeletonBox(width: 32, height: 32, radius: 8),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 工具栏占位：一排小方块按钮 + 分隔线，底部带分隔边框
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < 12; i++) ...[
                const SkeletonBox(width: 15, height: 15, radius: 5),
                if (i == 2 || i == 5 || i == 8)
                  const SkeletonBox(
                    width: 1,
                    height: 16,
                    radius: 1,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                  ),
              ],
            ],
          ),
        ),
        // 正文段落占位：多行不同宽度的文本行
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final lineMax = constraints.maxWidth;
                const fractions = [0.92, 0.78, 0.86, 0.64, 0.9, 0.72, 0.45];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < fractions.length; i++) ...[
                      SkeletonLine(
                        width: (lineMax * fractions[i]).clamp(48.0, lineMax),
                        height: 13,
                        radius: 7,
                      ),
                      SizedBox(height: i == 0 || i == 3 ? 22 : 14),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        // 底部状态条占位：保存状态文字 + 右侧操作小方块
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          child: Row(
            children: [
              const SkeletonLine(width: 110, height: 11, radius: 6),
              const Spacer(),
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                const SkeletonBox(width: 15, height: 15, radius: 5),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
