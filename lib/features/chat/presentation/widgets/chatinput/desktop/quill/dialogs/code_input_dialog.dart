import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/code_language.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
  String _selectedLanguage = CodeLanguageDetector.plainText.id;

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text;
    if (code.trim().isEmpty) return;
    widget.onSubmit(CodePayload(
      code: code,
      language: _selectedLanguage,
    ));
  }

  void _detectLanguage() {
    final code = _controller.text;
    if (code.trim().isEmpty) return;
    final detected = CodeLanguageDetector.detect(code);
    if (detected != CodeLanguageDetector.plainText && mounted) {
      setState(() {
        _selectedLanguage = detected.id;
      });
    }
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        items: [
                          for (final lang in CodeLanguageDetector.supported)
                            DropdownMenuItem<String>(
                              value: lang.id,
                              child: Text(lang.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _detectLanguage,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text('code_auto_detect'.tr()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _CodeEditor(
                controller: _controller,
                focusNode: _editorFocusNode,
                languageId: _selectedLanguage,
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
    required this.languageId,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String languageId;

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  final ScrollController _scrollController = ScrollController();
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final codeStyle = QuillStyleConfig.codeTextStyle(context);

    final numberHeight = codeStyle.fontSize! * codeStyle.height!;
    final numberStyle = codeStyle.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _lineCount; i++)
                  SizedBox(
                    height: numberHeight,
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: numberStyle,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: codeStyle,
              decoration: InputDecoration(
                hintText: 'code_editor_placeholder'.tr(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
