import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatActionItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const ChatActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: HugeIcon(icon: icon, color: colorScheme.onSurface, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}