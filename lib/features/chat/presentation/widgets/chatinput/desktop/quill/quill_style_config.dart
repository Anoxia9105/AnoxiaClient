import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'quill_code_line_number.dart';

/// Quill 编辑器样式配置类
///
/// 提供统一的富文本编辑器样式配置，适配应用主题：
/// - 段落样式
/// - 占位符样式
/// - 链接样式
/// - 代码块样式
class QuillStyleConfig {
  static TextStyle codeTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      // Web 端走系统字体，避免加载内置 CJK 大字体（Safari 卡顿来源）
      fontFamily: kIsWeb ? null : 'HarmonyOS',
      fontSize: QuillCodeLineNumber.fontSize,
      height: QuillCodeLineNumber.lineHeight,
      color: theme.colorScheme.onSurface,
    );
  }

  static DefaultStyles get(
    BuildContext context, {
    Color? color,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    //  基础文本样式
    final baseTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      color: color ?? colorScheme.onSurface,
    );

    // 基础间距配置
    const baseHorizontalSpacing = HorizontalSpacing(0, 0);
    final baseVerticalSpacing = compact
        ? VerticalSpacing.zero
        : const VerticalSpacing(6, 0);

    // 代码块样式
    final codeTextStyle = QuillStyleConfig.codeTextStyle(context);

    return DefaultStyles(
      // 正文段落样式
      paragraph: DefaultTextBlockStyle(
        baseTextStyle,
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        null,
      ),
      // 占位符样式
      placeHolder: DefaultTextBlockStyle(
        baseTextStyle.copyWith(color: colorScheme.onSurfaceVariant),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        null,
      ),
      // 链接样式
      link: baseTextStyle.copyWith(
        color: Colors.blueAccent,
        decoration: TextDecoration.underline,
      ),
      // 代码块样式
      inlineCode: InlineCodeStyle(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
        ),
        radius: const Radius.circular(4),
        style: codeTextStyle,
        header1: codeTextStyle,
        header2: codeTextStyle,
        header3: codeTextStyle,
      ),
      // 列表样式
      lists: DefaultListBlockStyle(
        baseTextStyle,
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        null,
        null,
        indentWidthBuilder: QuillCodeLineNumber.indentWidth,
        numberPointWidthBuilder: QuillCodeLineNumber.numberPointWidth,
      ),
      // 代码块样式
      code: DefaultListBlockStyle(
        codeTextStyle,
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
          ),
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        null,
      ),
      // 引用样式
      quote: DefaultTextBlockStyle(
        baseTextStyle,
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        BoxDecoration(
          border: Border(
            left: BorderSide(width: 4, color: colorScheme.outlineVariant),
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
