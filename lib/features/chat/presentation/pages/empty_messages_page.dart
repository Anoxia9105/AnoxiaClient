import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 空消息提示视图
class EmptyMessagesPage extends StatelessWidget {
  const EmptyMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedMessage01, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text('chat_no_messages'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}