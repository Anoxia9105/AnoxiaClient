import 'package:flutter/material.dart';

/// 联系人分组标题组件
///
/// 显示字母分组标签
class ContactGroupHeader extends StatelessWidget {
  final String tag;

  const ContactGroupHeader({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final safeTag = tag.trim().isEmpty ? '#' : tag.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      width: double.infinity,
      child: Text(
        safeTag,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
