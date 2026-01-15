import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Widget? child;
  final Widget? trailing;

  const SettingItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: HugeIcon(icon: icon, color: theme.colorScheme.primary),
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            trailing: trailing,
          ),
          if (child != null) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.only(top: 8), child: child),
          ],
        ],
      ),
    );
    const itemMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return Card(margin: itemMargin, child: content);
  }
}
