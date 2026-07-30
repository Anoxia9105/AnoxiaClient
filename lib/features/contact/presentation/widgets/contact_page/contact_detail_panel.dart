import 'package:flutter/material.dart';

/// 桌面端联系人详情右侧内容面板
///
/// 为详情页提供统一的卡片式容器和圆角裁剪
class ContactDetailPanel extends StatelessWidget {
  final Widget child;

  const ContactDetailPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
      ),
    );
  }
}
