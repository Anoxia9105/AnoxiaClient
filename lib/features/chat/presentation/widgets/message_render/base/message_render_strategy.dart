import 'package:flutter/material.dart';

import '../../../../../../framework/domain/ChatMessage.dart';

/// 消息渲染策略接口
///
/// 定义消息内容渲染的统一接口，采用策略模式处理不同类型消息的渲染
abstract class MessageRenderStrategy {
  /// 渲染消息内容核心组件
  ///
  /// [context] 构建上下文
  /// [message] 消息数据
  /// [textColor] 文本颜色（根据发送者和主题动态调整）
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  );
}
