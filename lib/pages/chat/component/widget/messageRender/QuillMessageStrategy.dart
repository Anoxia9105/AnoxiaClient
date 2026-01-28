import 'dart:convert';

import 'package:anoxia/pages/chat/component/widget/quill/QuillStyleConfig.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillFileBuild.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillImageBuild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class QuillMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    // 💡 不再在 Strategy 里持有控制器，而是交给具体的 Widget 处理
    return _QuillInternalRenderer(message: message);
  }
}

class _QuillInternalRenderer extends StatefulWidget {
  final ChatMessage message;
  const _QuillInternalRenderer({required this.message});

  @override
  State<_QuillInternalRenderer> createState() => _QuillInternalRendererState();
}

class _QuillInternalRendererState extends State<_QuillInternalRenderer> {
  late QuillController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  // 💡 关键：当列表项复用时，如果 message 变了，需要更新内容
  @override
  void didUpdateWidget(covariant _QuillInternalRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.payload?.quillDelta !=
        widget.message.payload?.quillDelta) {
      _initController();
    }
  }

  void _initController() {
    try {
      final delta = jsonDecode(widget.message.payload?.quillDelta ?? '[]');
      _controller = QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller.readOnly = true;
      _isError = false;
    } catch (e) {
      _isError = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) return const Text("消息格式错误");

    // 1. IntrinsicWidth 会测量子组件实际需要的最小宽度
    // 2. QuillEditorConfig 的 isReadOnly 配合特定的布局能实现自适应
    return IntrinsicWidth(
      child: QuillEditor.basic(
        controller: _controller,
        config: QuillEditorConfig(
          showCursor: false,
          autoFocus: false,
          expands: false, // 关键：不自动扩展高度
          scrollable: false, // 关键：禁止内部滚动，让气泡随内容大小变化
          padding: EdgeInsets.zero,
          customStyles: QuillStyleConfig.get(context),
          embedBuilders: [QuillImageBuild(), QuillFileBuild()],
        ),
      ),
    );
  }
}
