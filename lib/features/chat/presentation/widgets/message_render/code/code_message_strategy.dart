import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/code_language.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:flutter/material.dart';

import '../base/message_render_strategy.dart';

class CodeMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final code = message.payload?.code;
    if (code == null) {
      return Text(
        message.content,
        style: TextStyle(color: textColor),
      );
    }
    return _CodeMessageWidget(code: code);
  }
}

class _CodeMessageWidget extends StatelessWidget {
  const _CodeMessageWidget({required this.code});

  final CodePayload code;

  @override
  Widget build(BuildContext context) {
    final language = CodeLanguageDetector.fromId(code.displayLanguage) ??
        CodeLanguageDetector.plainText;
    final lines = code.code.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    final colorScheme = Theme.of(context).colorScheme;
    final codeStyle = QuillStyleConfig.codeTextStyle(context);
    final codeSpan = QuillSyntaxHighlighter.buildCodeSpan(
      context,
      code.code,
      language.id,
      codeStyle,
    );

    final numberHeight = codeStyle.fontSize! * codeStyle.height!;
    final numberStyle = codeStyle.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: 12,
      height: numberHeight / 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final codeWidget = DefaultTextStyle(
      style: codeStyle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 26, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${i + 1}', style: numberStyle),
                    ),
                ],
              ),
            ),
            Expanded(child: Text.rich(codeSpan)),
          ],
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: QuillStyleConfig.codeBlockDecoration(context),
      child: Stack(
        children: [
          codeWidget,
          Positioned(
            top: 4,
            right: 8,
            child: _LanguageBadge(language: language),
          ),
        ],
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.language});

  final CodeLanguage language;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        language.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
