import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:hugeicons/hugeicons.dart';

/// 联系人信息项组件
///
/// 以图标+标签-值的形式展示一条联系人信息，支持复制操作
class ContactInfoTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const ContactInfoTile({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            HugeIcon(
              icon: icon,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: SpacingToken.md),
          ],
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: SpacingToken.md),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}