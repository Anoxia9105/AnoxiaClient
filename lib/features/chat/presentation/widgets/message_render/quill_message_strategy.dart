import 'dart:convert';
import 'dart:ui' as ui;

import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_file_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_image_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_mention_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/quill_style_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

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
      return Text('chat_message_format_error'.tr());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.72;
        final targetWidth = _resolveTargetWidth(context, maxWidth);

        return SizedBox(
          width: targetWidth,
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
              customStyles: QuillStyleConfig.get(
                context,
                color: widget.textColor,
              ),
              embedBuilders: [
                QuillImageBuild(),
                QuillFileBuild(),
                QuillMentionBuild(),
              ],
            ),
          ),
        );
      },
    );
  }

  double _resolveTargetWidth(BuildContext context, double maxWidth) {
    if (_hasEmbed()) return maxWidth;

    final plain = _controller?.document.toPlainText() ?? '';
    final trimmed = plain.replaceAll(RegExp(r'\n+$'), '').trim();
    if (trimmed.isEmpty) {
      return 64;
    }

    if (trimmed.contains('\n')) {
      return maxWidth;
    }

    final textStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 15, height: 1.35);

    final painter = TextPainter(
      text: TextSpan(text: trimmed, style: textStyle),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final estimated = painter.width + 2;
    return estimated.clamp(64, maxWidth).toDouble();
  }

  bool _hasEmbed() {
    final dynamic opsJson = _controller?.document.toDelta().toJson();
    if (opsJson is! List) return false;

    for (final op in opsJson) {
      if (op['insert'] is Map) {
        return true;
      }
    }
    return false;
  }
}
