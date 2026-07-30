import 'package:flutter/material.dart';

/// 简化版列表项组件
///
/// 提供类似 [ListTile] 的布局，额外支持自定义圆角、选中状态背景色等。
/// 适用于聊天列表、设置页面等场景。
class SimpleListTile extends StatelessWidget {
  /// 左侧图标或组件
  final Widget? leading;
  /// 标题
  final Widget title;
  /// 副标题
  final Widget? subtitle;
  /// 右侧尾部组件
  final Widget? trailing;
  /// 点击回调
  final VoidCallback? onTap;
  /// 内边距
  final EdgeInsetsGeometry? padding;
  /// 内容间距
  final double contentSpacing;
  /// 是否选中
  final bool selected;
  /// 背景色
  final Color? tileColor;
  /// 选中时背景色
  final Color? selectedTileColor;
  /// 圆角半径
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.5))
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
