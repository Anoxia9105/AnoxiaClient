import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天操作项组件
///
/// 用于在聊天输入框的更多面板中显示单个操作按钮，
/// 包含图标和标签文字，支持点击交互
class ChatActionItem extends StatelessWidget {
  /// 图标，支持 HugeIcons 的图标类型
  final dynamic icon;

  /// 操作项标签文字
  final String label;

  /// 点击回调
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
