import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:flutter/material.dart';
import '../selectable_message_body.dart';

/// 与代码输入框（code_input_dialog）「行号 + 代码」布局保持一致的只读代码块。
///
/// 行号区与编辑框相同：独立背景色、右对齐、位数自适应宽度；
/// 代码保留原始换行且不软换行，长行横向滚动，行号与代码使用相同行高。
/// 消息渲染默认不带行号（只读场景行号无交互价值，且挤占气泡宽度），
/// 需要时可传 [showLineNumbers] 开启。
class CodeBlockView extends StatelessWidget {
  const CodeBlockView({
    super.key,
    required this.code,
    this.showLineNumbers = false,
    this.selectable = false,
  });

  final String code;

  /// 是否渲染行号区。
  final bool showLineNumbers;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    final codeStyle = QuillStyleConfig.codeTextStyle(context);
    final colorScheme = Theme.of(context).colorScheme;
    // 行号和代码区共用同一 strutStyle（含文字缩放），保证逐行对齐。
    final strutStyle = StrutStyle.fromTextStyle(
      codeStyle,
      forceStrutHeight: true,
    );
    // 使用同一段文字保留空行与缩进，避免跨行复制把多个 Text 的内容拼接丢失。
    final codeText = Text(
      lines.join('\n'),
      style: codeStyle,
      strutStyle: strutStyle,
      softWrap: false,
    );

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
                            style: QuillStyleConfig.codeLineNumberStyle(
                              context,
                            ),
                            strutStyle: strutStyle,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // 横向滚动避免长行换行后与行号错位。
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // 选择手势放在横向滚动容器内部，鼠标拖选先于滚动参与裁决。
                child: selectable
                    ? DefaultSelectionStyle(
                        selectionColor: colorScheme.primary.withValues(
                          alpha: 0.3,
                        ),
                        child: SelectableMessageBody(child: codeText),
                      )
                    : codeText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
