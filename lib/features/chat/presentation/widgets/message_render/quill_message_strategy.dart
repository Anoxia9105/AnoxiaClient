import 'package:flutter/material.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';
import 'quill_internal_renderer.dart';

/// 富文本消息渲染策略
///
/// 使用 Quill 编辑器渲染富文本消息，支持：
/// - 文本样式（加粗、斜体、颜色等）
/// - 图片嵌入
/// - 文件嵌入
/// - @提及用户高亮
/// - 动态宽度计算
class QuillMessageStrategy extends MessageRenderStrategy {
  QuillMessageStrategy({@visibleForTesting this.forceWasmRenderer = false});

  @visibleForTesting
  final bool forceWasmRenderer;

  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return QuillInternalRenderer(
      message: message,
      textColor: textColor,
      forceWasmRenderer: forceWasmRenderer,
    );
  }
}
