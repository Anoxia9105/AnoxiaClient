import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 空会话视图
class NoConversationPage extends StatelessWidget {
  const NoConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(),
      body: Center(child: Text('chat_no_conversations'.tr())),
    );
  }
}
