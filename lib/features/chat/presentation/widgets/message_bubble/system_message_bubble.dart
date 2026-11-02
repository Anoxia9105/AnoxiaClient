/// 系统消息气泡
///
/// 系统消息（如“xxx加入了群聊”）的专用渲染组件，无头像，居中显示。
library;

import 'package:flutter/material.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';

/// 系统消息气泡
class SystemMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final MessageRenderStrategy strategy;
  final Color textColor;
  final double horizontalPadding;
  final double verticalPadding;
  final double contentInset;

  const SystemMessageBubble({
    super.key,
    required this.message,
    required this.strategy,
    required this.textColor,
    required this.horizontalPadding,
    required this.verticalPadding,
    this.contentInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding,
      ),
      child: strategy.buildContent(context, message, textColor),
    );
  }
}
