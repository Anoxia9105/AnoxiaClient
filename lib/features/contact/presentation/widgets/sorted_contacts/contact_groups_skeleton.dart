import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// 联系人分组列表骨架屏
///
/// 用于在联系人加载过程中显示占位内容
class ContactGroupsSkeleton extends StatelessWidget {
  const ContactGroupsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const count = 12;
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final showHeader = index == 0 || index == 5 || index == 9;
        final nameWidth = 90.0 + (index % 4) * 22;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: SkeletonLine(width: 16, height: 12),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                dense: true,
                leading: const SkeletonBox(width: 40, height: 40, radius: 8),
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonLine(width: nameWidth, height: 13),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SkeletonLine(width: 72, height: 10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
