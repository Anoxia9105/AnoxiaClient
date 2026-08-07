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

  /// 编辑区内容 padding，行号区与其保持一致的上下留白，保证逐行对齐；
  /// 光标跟随滚动时需折算这一偏移。
  static const _contentPadding = EdgeInsets.fromLTRB(8, 12, 12, 12);

  int _lineCount = 1;

  final GlobalKey<EditableTextState> _editableKey = GlobalKey();

  /// 外层垂直滚动（行号区与编辑区同轴滚动，天然对齐）。
  final ScrollController _vScrollController = ScrollController();

  /// 内层水平滚动（长行不换行，超出后横向滚动）。
  final ScrollController _hScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    // 打开对话框后自动聚焦编辑区，可直接开始输入。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _vScrollController.dispose();
    _hScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final text = widget.controller.text;
    // 每次文本变化都刷新：行号宽度按位数自适应，占位提示随空文本显隐。
    setState(() {
      _lineCount = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    });
    _scheduleFollowCaret();
  }

  /// 光标移出可视区时滚动到可视区（横向超长行 + 纵向行数超出高度）。
  void _scheduleFollowCaret() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _followCaret();
    });
  }

  void _followCaret() {
    final state = _editableKey.currentState;
    final selection = widget.controller.selection;
    if (state == null || !selection.isValid) return;

    final Rect caretRect;
    try {
      caretRect = state.renderEditable.getLocalRectForCaret(
        TextPosition(offset: selection.baseOffset),
      );
    } catch (_) {
      return;
    }
    // RenderEditable 位于 contentPadding 内，坐标需折算为滚动内容坐标。
    final caretLeft = caretRect.left + _contentPadding.left;
    final caretRight = caretRect.right + _contentPadding.left;
    final caretTop = caretRect.top + _contentPadding.top;
    final caretBottom = caretRect.bottom + _contentPadding.top;

    if (_hScrollController.hasClients) {
      final hPosition = _hScrollController.position;
      if (caretLeft < hPosition.pixels) {
        _hScrollController.jumpTo(caretLeft);
      } else if (caretRight > hPosition.pixels + hPosition.viewportDimension) {
        _hScrollController.jumpTo(caretRight - hPosition.viewportDimension);
      }
    }
    if (_vScrollController.hasClients) {
      final vPosition = _vScrollController.position;
      if (caretTop < vPosition.pixels) {
        _vScrollController.jumpTo(caretTop);
      } else if (caretBottom > vPosition.pixels + vPosition.viewportDimension) {
        _vScrollController.jumpTo(caretBottom - vPosition.viewportDimension);
      }
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
    // 行号和代码区共用同一 strutStyle，确保基线对齐而非依赖 SizedBox+Center 奇呈。
    final strutStyle = StrutStyle.fromTextStyle(codeStyle, forceStrutHeight: true);
    final numberStyle = QuillStyleConfig.codeLineNumberStyle(context);

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 滚动视口高度：行号区与编辑区都以它为最小高度，内容不足一屏时
          // 两区仍占满整个对话框（不能用 Row.stretch —— 滚动容器内纵向无界，
          // stretch 会产生无限高度约束）。
          final minHeight = constraints.maxHeight;
          return SingleChildScrollView(
            controller: _vScrollController,
            physics: const ClampingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 行号区：独立背景色、右对齐、位数自适应宽度、高度占满整个编辑区。
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: ColoredBox(
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: _contentPadding.top,
                      ),
                      child: SizedBox(
                        width: QuillStyleConfig.codeGutterWidth(
                          context,
                          _lineCount,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < _lineCount; i++)
                              Text(
                                '${i + 1}',
                                style: numberStyle,
                                strutStyle: strutStyle,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 代码编辑区：forceLine 关闭 + 宽度不设上限 → 长行不换行，
                // 超出可视宽后内层横向滚动并跟随光标；行数超出高度时随
                // 外层垂直滚动（与行号区同轴滚动，逐行始终对齐）。
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: SingleChildScrollView(
                      controller: _hScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // 至少占满可视宽，保证空内容也可点击聚焦。
                          minWidth: constraints.maxWidth,
                        ),
                      child: Padding(
                        padding: _contentPadding,
                        // passthrough：透传最小高度/宽度约束，保证空内容时编辑区
                        // 仍占满可视区域（默认 loose 会清空 min 约束导致收缩）。
                        child: Stack(
                          fit: StackFit.passthrough,
                          alignment: Alignment.topLeft,
                          children: [
                            // 占位提示：覆盖在空白编辑区之上，与首行文本同位置同样式。
                            // 不能用 InputDecorator —— 横向滚动容器内宽度无上限，
                            // 其断言要求有限宽度。
                            if (widget.controller.text.isEmpty)
                              Text(
                                'code_editor_placeholder'.tr(),
                                style: codeStyle.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                strutStyle: strutStyle,
                                maxLines: 1,
                              ),
                            Focus(
                              canRequestFocus: false,
                              onKeyEvent: _handleKeyEvent,
                              child: EditableText(
                                key: _editableKey,
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                style: codeStyle,
                                strutStyle: strutStyle,
                                cursorColor: colorScheme.primary,
                                backgroundCursorColor: colorScheme.primary,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                // 关闭「占满整行宽」：宽度随内容走，配合无上限
                                // 宽度约束实现长行不软换行。
                                forceLine: false,
                                scrollPhysics: const ClampingScrollPhysics(),
                                onSelectionChanged: (_, _) =>
                                    _scheduleFollowCaret(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
