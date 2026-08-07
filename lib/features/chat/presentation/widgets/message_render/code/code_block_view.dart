import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:flutter/material.dart';

/// 与代码输入框（code_input_dialog）「行号 + 代码」布局保持一致的只读代码块。
///
/// 行号区与编辑框相同：独立背景色、右对齐、位数自适应宽度；
/// 代码逐行渲染且不软换行，长行横向滚动，保证行号与代码逐行对齐。
/// 消息渲染默认不带行号（只读场景行号无交互价值，且挤占气泡宽度），
/// 需要时可传 [showLineNumbers] 开启。
class CodeBlockView extends StatelessWidget {
  const CodeBlockView({super.key, required this.code, this.showLineNumbers = false});

  final String code;

  /// 是否渲染行号区。
  final bool showLineNumbers;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    final codeStyle = QuillStyleConfig.codeTextStyle(context);
    final colorScheme = Theme.of(context).colorScheme;
    // 行号和代码区共用同一 strutStyle（含文字缩放），保证逐行对齐。
    final strutStyle = StrutStyle.fromTextStyle(codeStyle, forceStrutHeight: true);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: QuillStyleConfig.codeBlockDecoration(context),
      child: Padding(
        // 带行号时左侧留白由行号区承担；不带行号时补回左侧间距。
        padding: EdgeInsets.fromLTRB(showLineNumbers ? 0 : 12, 12, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLineNumbers) ...[
              // 行号区：与编辑框一致的背景色、右对齐、位数自适应宽度
              ColoredBox(
                color: colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: QuillStyleConfig.codeGutterWidth(
                      context,
                      lines.length,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          Text(
                            '${i + 1}',
                            style: QuillStyleConfig.codeLineNumberStyle(context),
                            strutStyle: strutStyle,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // 逐行渲染保证行号与代码对齐；横向滚动避免长行换行后错位。
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in lines)
                      Text(
                        line,
                        style: codeStyle,
                        strutStyle: strutStyle,
                        maxLines: 1,
                        softWrap: false,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
