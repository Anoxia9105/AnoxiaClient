/// Quill 代码块行号与语言标签渲染组件。
///
/// 为 Quill 编辑器中的代码块提供紧凑、精致的固定宽度行号栏
/// 和左上角的语言标签，行号与代码高亮均由 Quill 稳定驱动。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'code_language.dart';

/// Builds a clearly visible leading number for every code-block line.
abstract final class QuillCodeLineNumber {
  /// 行号栏宽度（左侧留白 + 数字）。
  static const double gutterWidth = 32;

  /// 代码字体大小。
  static const double fontSize = 13;

  /// 代码行高。
  static const double lineHeight = 1.5;

  /// Quill 代码块内置的上下内边距（与 flutter_quill 包内写死的一致），
  /// 语言标签依此定位在代码块顶部留白处，避免与首行代码重叠。
  static const double blockTopPadding = 16;

  /// 计算文本缩进宽度，将代码文本保持在固定间距的右侧列中。
  static HorizontalSpacing indentWidth(
    Block block,
    BuildContext context,
    int count,
    LeadingBlockNumberPointWidth numberPointWidth,
  ) {
    final styles = QuillStyles.getStyles(context, false);
    final fontSize = styles?.paragraph?.style.fontSize ?? 14;
    final attributes = block.style.attributes;
    final indent = attributes[Attribute.indent.key]?.value;
    final extraIndent = indent is int ? fontSize * indent : 0.0;

    if (attributes.containsKey(Attribute.codeBlock.key)) {
      return HorizontalSpacing(gutterWidth + extraIndent, 0);
    }
    if (attributes.containsKey(Attribute.blockQuote.key)) {
      return HorizontalSpacing(fontSize + extraIndent, 0);
    }
    if (attributes.containsKey(Attribute.list.key)) {
      final listWidth = attributes[Attribute.list.key] == Attribute.ol
          ? numberPointWidth(fontSize, count)
          : fontSize * 2;
      return HorizontalSpacing(listWidth + extraIndent, 0);
    }
    return HorizontalSpacing(extraIndent, 0);
  }

  /// 计算列表编号点宽度。
  static double numberPointWidth(double fontSize, int count) => gutterWidth;

  /// 构建代码块行号前导组件。
  ///
  /// [node] 当前 Quill 节点。
  /// [config] 前导配置。
  /// [controller] Quill 编辑器控制器，用于语言切换。
  /// [showLanguageBadge] 是否在第一行显示语言标签。
  static Widget? build(
    Node node,
    LeadingConfig config, {
    QuillController? controller,
    bool showLanguageBadge = true,
  }) {
    if (config.attribute.key != Attribute.codeBlock.key) {
      return null;
    }

    final lineNumber = config.getIndexNumberByIndent ?? '${config.index ?? 1}';
    return _CodeBlockLeading(
      node: node,
      lineNumber: lineNumber,
      style: config.style,
      showLanguage: showLanguageBadge && config.index == 1,
      controller: controller,
    );
  }
}

class _CodeBlockLeading extends StatefulWidget {
  final Node node;
  final String lineNumber;
  final TextStyle? style;
  final bool showLanguage;
  final QuillController? controller;

  const _CodeBlockLeading({
    required this.node,
    required this.lineNumber,
    required this.style,
    required this.showLanguage,
    required this.controller,
  });

  @override
  State<_CodeBlockLeading> createState() => _CodeBlockLeadingState();
}

class _CodeBlockLeadingState extends State<_CodeBlockLeading> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = CodeLanguageDetector.resolveForLine(widget.node);

    final number = Container(
      alignment: AlignmentDirectional.topEnd,
      width: QuillCodeLineNumber.gutterWidth,
      padding: const EdgeInsetsDirectional.only(end: 6, top: 2),
      // 行号栏使用比代码区略深的底色 + 细分割线，形成精致的沟槽效果
      decoration: BoxDecoration(
        color:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Text(
        widget.lineNumber,
        textAlign: TextAlign.end,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          // Web 端走系统字体，避免加载内置 CJK 大字体（Safari 卡顿来源）
          fontFamily: kIsWeb ? null : 'HarmonyOS',
          fontSize: QuillCodeLineNumber.fontSize - 1,
          height: QuillCodeLineNumber.lineHeight,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    if (!widget.showLanguage) return number;

    // 语言标签稳定地置于代码块顶部留白（首行上方），不依赖视口测量，
    // 避免 Overlay 测量带来的抖动/不稳定。
    return Stack(
      clipBehavior: Clip.none,
      children: [
        number,
        Positioned(
          left: QuillCodeLineNumber.gutterWidth,
          top: -QuillCodeLineNumber.blockTopPadding,
          child: QuillCodeLanguageBadge(
            language: language,
            onSelected: widget.controller == null ? null : _setLanguage,
          ),
        ),
      ],
    );
  }

  void _setLanguage(String languageId) {
    final controller = widget.controller;
    final block = widget.node.parent;
    if (controller == null || block is! Block) return;

    controller.formatText(
      block.documentOffset,
      block.length,
      Attribute.clone(Attribute.codeBlock, languageId),
    );
  }
}

/// 代码语言标签组件，显示当前代码块的语言并可切换。
class QuillCodeLanguageBadge extends StatelessWidget {
  /// 当前语言。
  final CodeLanguage language;

  /// 语言切换回调，为 `null` 时不可切换。
  final ValueChanged<String>? onSelected;

  const QuillCodeLanguageBadge({
    super.key,
    required this.language,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
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
          ),
          if (onSelected != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (onSelected == null) return IgnorePointer(child: badge);

    return PopupMenuButton<String>(
      tooltip: 'Code language',
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => CodeLanguageDetector.supported
          .map(
            (item) => PopupMenuItem<String>(
              value: item.id,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: item.id == language.id
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                  Text(item.label),
                ],
              ),
            ),
          )
          .toList(growable: false),
      child: badge,
    );
  }
}
