import 'dart:convert';

import 'package:anoxia/pages/chat/component/widget/quill/QuillStyleConfig.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillFileBuild.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillImageBuild.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import '../quill/embedBuilder/QuillMentionBuild.dart';
import 'base/MessageRenderStrategy.dart';

class QuillMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return _QuillInternalRenderer(message: message, textColor: textColor);
  }
}

class _QuillInternalRenderer extends StatefulWidget {
  final ChatMessage message;
  final Color textColor;

  const _QuillInternalRenderer({
    required this.message,
    required this.textColor,
  });

  @override
  State<_QuillInternalRenderer> createState() => _QuillInternalRendererState();
}

class _QuillInternalRendererState extends State<_QuillInternalRenderer> {
  QuillController? _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _QuillInternalRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.payload?.quillDelta !=
        widget.message.payload?.quillDelta) {
      _controller?.dispose();
      _initController();
      setState(() {});
    }
  }

  void _initController() {
    try {
      final delta = jsonDecode(widget.message.payload?.quillDelta ?? '[]');
      _controller = QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller?.readOnly = true;
      _isError = false;
    } catch (e) {
      _controller = null;
      _isError = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError || _controller == null) {
      return Text("chat_message_format_error".tr());
    }

    return SizedBox(
      width: double.infinity,
      child: QuillEditor.basic(
        controller: _controller!,
        config: QuillEditorConfig(
          textSelectionThemeData: TextSelectionThemeData(
            selectionColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
          enableSelectionToolbar: false,
          showCursor: false,
          autoFocus: false,
          expands: false,
          scrollable: false,
          padding: EdgeInsets.zero,
          customStyles: QuillStyleConfig.get(context, color: widget.textColor),
          embedBuilders: [
            QuillImageBuild(),
            QuillFileBuild(),
            QuillMentionBuild(),
          ],
        ),
      ),
    );
  }
}
