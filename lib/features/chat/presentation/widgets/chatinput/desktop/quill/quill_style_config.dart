import 'package:flutter/foundation.dart';
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
  static TextStyle codeTextStyle(BuildContext context) {
    const fontSize = 13.0;
    const lineHeight = 1.5;
    final theme = Theme.of(context);
    return TextStyle(
      fontFamily: kIsWeb ? null : 'HarmonyOS',
      fontSize: fontSize,
      height: lineHeight,
      color: theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// 代码块背景装饰：深色模式用更柔和的半透明底色，配合细边框收敛轮廓，
  /// 使代码块在输入框中更显紧凑、精致。
  static BoxDecoration codeBlockDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.55 : 0.85,
      ),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(6),
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
        indentWidthBuilder: (block, context, count, numberPointWidth) =>
            const HorizontalSpacing(16, 16),
        numberPointWidthBuilder: (fontSize, count) => 24.0,
      ),
      // 代码块样式
      code: DefaultListBlockStyle(
        codeTextStyle,
        baseHorizontalSpacing,
        // 非紧凑模式顶部留出 16px 给语言徽章（位于首行上方、块内），
        // 底部留 6px 与下一条消息/段落分隔；紧凑模式（消息渲染）无需徽章
        // 头部，保持零间距。
        compact
            ? VerticalSpacing.zero
            : const VerticalSpacing(16, 6),
        VerticalSpacing.zero,
        QuillStyleConfig.codeBlockDecoration(context),
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
