import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 设置项卡片组件
///
/// 用于展示设置页面中的各个设置项，包含标题、副标题、图标和可选的子内容
class SettingItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Widget? child;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;

  const SettingItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.child,
    this.trailing,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: contentPadding ?? const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
