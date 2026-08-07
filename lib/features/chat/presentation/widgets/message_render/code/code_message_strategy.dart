import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
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
    final lines = code.code.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    final colorScheme = Theme.of(context).colorScheme;
    final codeStyle = QuillStyleConfig.codeTextStyle(context);

    // 行号使用与代码一致的文本样式行高（含文字缩放），保证逐行对齐。
    final numberHeight = MediaQuery.textScalerOf(context)
        .scale(codeStyle.fontSize! * codeStyle.height!);
    final numberStyle = codeStyle.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: QuillStyleConfig.codeBlockDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < lines.length; i++)
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
            Expanded(child: Text(code.code, style: codeStyle)),
          ],
        ),
      ),
    );
  }
}
