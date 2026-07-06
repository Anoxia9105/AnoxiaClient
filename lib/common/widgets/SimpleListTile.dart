import 'package:flutter/material.dart';

class SimpleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double contentSpacing;
  final bool selected;
  final Color? tileColor;
  final Color? selectedTileColor;

  // 新增圆角属性
  final BorderRadius? borderRadius;

  const SimpleListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.contentSpacing = 12.0,
    this.selected = false,
    this.tileColor,
    this.selectedTileColor,
    this.borderRadius, // 初始化
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveBgColor = selected
        ? (selectedTileColor ??
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2))
        : tileColor;

    final Widget content = Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: contentSpacing)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: contentSpacing), trailing!],
        ],
      ),
    );

    return Material(
      color: effectiveBgColor ?? Colors.transparent,
      borderRadius: borderRadius,
      // 如果设置了圆角，开启抗锯齿剪裁，确保背景色和水波纹不溢出
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: onTap != null
          ? InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: onTap,
              borderRadius: borderRadius,
              child: content,
            )
          : content,
    );
  }
}
