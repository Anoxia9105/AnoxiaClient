import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
      fontFamily: 'JetBrainsMono',
      fontFamilyFallback: const ['NotoSansSC'],
      fontSize: fontSize,
      height: lineHeight,
      color: theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// 行号文字样式（与代码文本同字号行高，仅颜色不同），保证逐行对齐。
  static TextStyle codeLineNumberStyle(BuildContext context) {
    return codeTextStyle(context).copyWith(
      color: Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(alpha: 0.6),
    );
  }

  /// 行号区宽度：等宽数字宽度 ≈ fontSize×0.65（含文字缩放），
  /// 加上左右各 8px 留白。编辑框与消息渲染共用，保证观感一致。
  static double codeGutterWidth(BuildContext context, int lineCount) {
    final fontSize = codeTextStyle(context).fontSize!;
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(fontSize * 0.65) * lineCount.toString().length +
        16;
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
      borderRadius: BorderRadius.circular(RadiusToken.sm),
    );
  }

  static DefaultStyles get(
    BuildContext context, {
    Color? color,
    bool compact = false,
    bool forEditing = false,
    QuillCheckboxBuilder? checkboxBuilder,
    VerticalSpacing? listLineSpacing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 紧凑消息正文与输入框统一用中等字重，笔记等非紧凑视图沿用原样式。
    final useMediumWeight = forEditing || compact;

    //  基础文本样式
    final baseTextStyle = TextStyle(
      fontFamily: theme.textTheme.bodyLarge?.fontFamily,
      fontFamilyFallback: theme.textTheme.bodyLarge?.fontFamilyFallback,
      // 可变字体显式设置字重轴，让中文输入笔画更清晰，避免只合成加粗。
      fontWeight: useMediumWeight ? FontWeight.w500 : null,
      fontVariations: useMediumWeight ? const [FontVariation('wght', 500)] : null,
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
      bold: useMediumWeight
          ? const TextStyle(
              fontWeight: FontWeight.w700,
              fontVariations: [FontVariation('wght', 700)],
            )
          : null,
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
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      // 代码块样式
      inlineCode: InlineCodeStyle(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
        ),
        radius: const Radius.circular(RadiusToken.sm),
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
        listLineSpacing ?? VerticalSpacing.zero,
        null,
        // 任务列表复选框放大到 18px，点击区域更大、更易操作。
        checkboxBuilder ?? const _TaskCheckboxBuilder(),
        // 块级内容的单行水平内衬（每行正文的左右 padding）。
        //
        // ⚠️ 这个回调对**每一个 Block** 都会被调用（不只是列表），返回的是该块内
        // 每一行正文的左右 padding：右侧会直接吃掉正文可用宽度，左侧会与 leading
        // （复选框 / 编号 / 行号）共用同一个槽位。
        //
        // 右侧必须恒为 0 —— flutter_quill 的默认实现里右侧也永远是 0。原因：
        // 消息气泡的宽度是按正文实测出来的
        // （quill_internal_renderer.dart 的 `_measureInlineContentWidth`），渲染端
        // 多出来的 16px 右内衬会让正文可用宽度比气泡窄 16px，**行尾最后一个字被挤到
        // 下一行**。普通段落是 Line 节点，走段落样式的 horizontalSpacing(0,0)，
        // 所以只有块级内容（引用 / 列表 / 代码块）会中招。
        //
        // 左侧保留 16px 做页面留白（测量端按 24px = 16 + 余量预留）；任务列表的
        // 引导槽加宽到 28px —— 18px 复选框按真实尺寸渲染，与正文之间留约 10px 间距，
        // 避免复选框紧贴文字。
        indentWidthBuilder: (block, context, count, numberPointWidth) {
          final listAttr = block.style.attributes[Attribute.list.key];
          final isCheck =
              listAttr == Attribute.checked || listAttr == Attribute.unchecked;
          return isCheck
              ? const HorizontalSpacing(28, 0)
              : const HorizontalSpacing(16, 0);
        },
        numberPointWidthBuilder: (fontSize, count) => 24.0,
      ),
      // 代码块样式
      code: DefaultListBlockStyle(
        codeTextStyle,
        baseHorizontalSpacing,
        // 紧凑模式（消息渲染）顶部/底部保持零间距；
        // 非紧凑模式（输入框）顶部留 8px 与段落分隔，底部留 6px。
        compact
            ? VerticalSpacing.zero
            : const VerticalSpacing(8, 6),
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
          borderRadius: BorderRadius.circular(RadiusToken.sm),
        ),
      ),
    );
  }
}

/// 任务列表复选框：18px 圆角方框，选中态主题色填充 + 勾号，带点击反馈。
class _TaskCheckboxBuilder implements QuillCheckboxBuilder {
  const _TaskCheckboxBuilder();

  static const double _size = 18;

  @override
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // 复选框与正文之间留 8px 空隙（默认实现自带 end: size/2 间距，
    // 自定义样式丢失了它，导致复选框紧贴文字）。
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: SizedBox.square(
        dimension: _size,
        child: Material(
          color: isChecked ? colorScheme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isChecked
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: .4),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(RadiusToken.sm),
          ),
          child: InkWell(
            onTap: () => onChanged(!isChecked),
            borderRadius: BorderRadius.circular(RadiusToken.sm),
            child: isChecked
                ? Icon(
                    Icons.check,
                    size: _size - 5,
                    color: colorScheme.onPrimary,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
