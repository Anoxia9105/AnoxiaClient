import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/code_language.dart';
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
  String _selectedLanguage = CodeLanguageDetector.plainText.id;
  bool _hasSelection = false;

  @override
  void dispose() {
    _controller.dispose();
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

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          ),
          title: Text('code_editor_title'.tr()),
          actions: [
            TextButton(
              onPressed: _controller.text.trim().isEmpty ? null : _submit,
              child: Text('toolbar_send'.tr()),
            ),
          ],
        ),
        body: Column(
          children: [
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
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Courier New', 'Consolas'],
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'code_editor_placeholder'.tr(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) {
                  final hasSelection = _controller.text.trim().isNotEmpty;
                  if (hasSelection != _hasSelection) {
                    setState(() {
                      _hasSelection = hasSelection;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
