import 'package:flutter/material.dart';

import '../../../../../../framework/domain/ChatMessage.dart';

abstract class MessageRenderStrategy {
  /// 渲染消息内容核心组件
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  );
}
