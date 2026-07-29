import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Quill 编辑器样式配置类
///
/// 提供统一的富文本编辑器样式配置，适配应用主题：
/// - 段落样式
/// - 占位符样式
/// - 链接样式
/// - 代码块样式
class QuillStyleConfig {
  static DefaultStyles get(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    final baseTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      color: color ?? colorScheme.onSurface,
    );
    final codeTextStyle = baseTextStyle.copyWith(
      fontFamily: 'monospace',
      fontSize: 13.5,
      height: 1.45,
    );
    final codeBackground = colorScheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseTextStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        baseTextStyle.copyWith(color: colorScheme.onSurfaceVariant),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      link: baseTextStyle.copyWith(
        color: Colors.blueAccent,
        decoration: TextDecoration.underline,
      ),
      inlineCode: InlineCodeStyle(
        backgroundColor: codeBackground,
        radius: const Radius.circular(4),
        style: codeTextStyle,
        header1: codeTextStyle,
        header2: codeTextStyle,
        header3: codeTextStyle,
      ),
      code: DefaultListBlockStyle(
        codeTextStyle,
        const HorizontalSpacing(10, 10),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          color: codeBackground,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        null,
      ),
    );
  }
}
