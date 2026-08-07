import 'dart:math';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeInputDialog extends StatefulWidget {
  const CodeInputDialog({
    super.key,
    required this.onSubmit,
    this.onCancel,
  });

  final ValueChanged<CodePayload> onSubmit;
  final VoidCallback? onCancel;

  @override
  State<CodeInputDialog> createState() => _CodeInputDialogState();
}

class _CodeInputDialogState extends State<CodeInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 监听文本变化以刷新发送按钮的启用状态。
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text;
    if (code.trim().isEmpty) return;
    widget.onSubmit(CodePayload(code: code));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.7).clamp(600.0, 900.0);
    final dialogHeight = (screenSize.height * 0.7).clamp(400.0, 700.0);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'code_editor_title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.text.trim().isEmpty ? null : _submit,
                    child: Text('toolbar_send'.tr()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _CodeEditor(
                controller: _controller,
                focusNode: _editorFocusNode,
                onSubmit: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeEditor extends StatefulWidget {
  const _CodeEditor({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  /// Tab 键插入的缩进宽度。
  static const _indent = '    ';

  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
    // 打开对话框后自动聚焦编辑区，可直接开始输入。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    super.dispose();
  }

  void _updateLineCount() {
    final text = widget.controller.text;
    final count = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    if (count != _lineCount) {
      setState(() {
        _lineCount = count;
      });
    }
  }

  /// 代码编辑快捷键：Tab 插入 4 空格缩进（替代默认的焦点切换），
  /// Ctrl/Cmd + Enter 直接发送。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.tab) {
      final value = widget.controller.value;
      final selection = value.selection;
      if (!selection.isValid) return KeyEventResult.ignored;
      widget.controller.value = TextEditingValue(
        text: value.text.replaceRange(selection.start, selection.end, _indent),
        selection: TextSelection.collapsed(
          offset: selection.start + _indent.length,
        ),
      );
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      widget.onSubmit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final codeStyle = QuillStyleConfig.codeTextStyle(context);
    final textScaler = MediaQuery.textScalerOf(context);
    // 行号和代码区共用同一 strutStyle，确保基线对齐而非依赖 SizedBox+Center 奇呈。
    final strutStyle = StrutStyle.fromTextStyle(codeStyle, forceStrutHeight: true);

    final numberStyle = codeStyle.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // 等宽字体每个数字宽度 ≈ fontSize×0.65，加左右 padding 10px
    final numColWidth =
        textScaler.scale(codeStyle.fontSize! * 0.65) *
            _lineCount.toString().length +
        20;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 行号区域：独立背景色、靠右对齐、位数自适应宽度
            ColoredBox(
              color: colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                child: SizedBox(
                  width: numColWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _lineCount; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${i + 1}',
                            style: numberStyle,
                            strutStyle: strutStyle,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // 代码编辑区：禁止软换行，横向可滚动
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      // 最小宽度取可用宽和 2000px 中较大值，消除软换行
                      width: max(constraints.maxWidth, 2000),
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: codeStyle,
                          strutStyle: strutStyle,
                          decoration: InputDecoration(
                            hintText: 'code_editor_placeholder'.tr(),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.fromLTRB(8, 12, 12, 12),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
