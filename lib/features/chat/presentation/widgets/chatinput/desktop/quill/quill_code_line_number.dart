/// Quill 代码块行号与语言标签渲染组件。
///
/// 为 Quill 编辑器中的代码块提供固定宽度的行号栏
/// 和悬浮的语言选择标签。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'code_language.dart';

/// Builds a clearly visible leading number for every code-block line.
abstract final class QuillCodeLineNumber {
  /// 行号栏宽度。
  static const double gutterWidth = 40;

  /// 行号字体大小。
  static const double fontSize = 14;

  /// 行号行高。
  static const double lineHeight = 1.15;

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
  static const double _badgeWidth = 92;
  final GlobalKey _numberKey = GlobalKey();
  final OverlayPortalController _overlayController = OverlayPortalController();
  double _lineWidth = 0;
  double _badgeTop = 0;
  double _badgeRight = 8;
  bool _isOverlayShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLanguage) {
      WidgetsBinding.instance.addPostFrameCallback(_measureAndShow);
    }
  }

  @override
  void didUpdateWidget(covariant _CodeBlockLeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLanguage) {
      WidgetsBinding.instance.addPostFrameCallback(_measureAndShow);
    } else if (oldWidget.showLanguage && _isOverlayShown) {
      _overlayController.hide();
      _isOverlayShown = false;
    }
  }

  void _measureAndShow(Duration _) {
    if (!mounted || !widget.showLanguage) return;

    final targetRenderObject = _numberKey.currentContext?.findRenderObject();
    RenderObject? renderObject = targetRenderObject;
    var visibleWidth = double.infinity;
    while (renderObject != null) {
      if (renderObject is RenderBox && renderObject.hasSize) {
        final width = renderObject.size.width;
        if (width > _badgeWidth + QuillCodeLineNumber.gutterWidth &&
            width < visibleWidth) {
          visibleWidth = width;
        }
      }
      renderObject = renderObject.parent;
    }
    if (targetRenderObject is RenderBox && targetRenderObject.hasSize) {
      final viewportWidth = MediaQuery.sizeOf(context).width;
      final targetPosition = targetRenderObject.localToGlobal(Offset.zero);
      final targetLeft = targetPosition.dx;
      _badgeTop = targetPosition.dy;
      final viewportAvailable = viewportWidth - targetLeft - 8;
      if (viewportAvailable > _badgeWidth && viewportAvailable < visibleWidth) {
        visibleWidth = viewportAvailable;
      }
      _badgeRight = (viewportWidth - targetLeft - visibleWidth + 8)
          .clamp(8.0, viewportWidth - _badgeWidth)
          .toDouble();
    }
    if (!visibleWidth.isFinite) return;

    if (_lineWidth != visibleWidth) {
      setState(() => _lineWidth = visibleWidth);
    }
    _overlayController.show();
    _isOverlayShown = true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = CodeLanguageDetector.resolveForLine(widget.node);
    final number = Container(
      key: _numberKey,
      alignment: AlignmentDirectional.topStart,
      width: QuillCodeLineNumber.gutterWidth,
      child: Text(
        widget.lineNumber,
        textAlign: TextAlign.start,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: colorScheme.onSurfaceVariant,
          // Web 端走系统字体，避免加载内置 CJK 大字体（Safari 卡顿来源）
          fontFamily: kIsWeb ? null : 'HarmonyOS',
          fontSize: QuillCodeLineNumber.fontSize,
          height: QuillCodeLineNumber.lineHeight,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    if (!widget.showLanguage) return number;

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (overlayContext) {
        if (_lineWidth <= _badgeWidth) return const SizedBox.shrink();
        return Positioned(
          top: _badgeTop,
          right: _badgeRight,
          child: SizedBox(
            width: _badgeWidth,
            child: QuillCodeLanguageBadge(
              language: language,
              onSelected: widget.controller == null ? null : _setLanguage,
            ),
          ),
        );
      },
      child: number,
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
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              language.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onSelected != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
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
