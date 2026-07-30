import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 联系人详情骨架屏
///
/// 用于在联系人详情加载过程中显示占位内容
class ContactDetailSkeleton extends StatelessWidget {
  const ContactDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 32),
          SkeletonBox(width: 96, height: 96, radius: 16),
          SizedBox(height: 14),
          SkeletonBox(width: 140, height: 20, radius: 6),
          SizedBox(height: 8),
          SkeletonBox(width: 80, height: 14, radius: 6),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _InfoCardSkeleton(),
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonBox(height: 48, radius: 12),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonBox(height: 48, radius: 12),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  const _InfoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _InfoLine(),
        _InfoLine(),
        _InfoLine(),
        _InfoLine(),
        _InfoLine(),
        _InfoLine(),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SkeletonBox(width: 18, height: 18, radius: 4),
          SizedBox(width: 12),
          SkeletonBox(width: 72, height: 12, radius: 4),
          SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 12, radius: 4)),
        ],
      ),
    );
  }
}