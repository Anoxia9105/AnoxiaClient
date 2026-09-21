import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

/// 空消息提示视图
class EmptyMessagesPage extends StatelessWidget {
  const EmptyMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedMessage01, size: 40, color: onVariant),
          const SizedBox(height: 12),
          Text('chat_no_messages'.tr(), style: TextStyle(color: onVariant, fontSize: 14)),
        ],
      ),
    );
  }
}