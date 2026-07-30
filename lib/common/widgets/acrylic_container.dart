import 'dart:ui';

import 'package:flutter/material.dart';

/// 亚克力容器组件
///
/// 支持模糊背景、渐变叠加、主题适配和阴影效果。
class AcrylicContainer extends StatelessWidget {
  /// 背景组件（图片/渐变等）
  final Widget background;

  /// 模糊强度
  final double blurSigma;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 边框
  final BoxBorder? border;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 内容组件
  final Widget child;

  /// 点击背景回调
  final VoidCallback? onBackgroundTap;

  /// 渐变叠加层
  final Gradient? overlayGradient;

  /// 是否自动根据主题生成遮罩
  final bool autoThemeOverlay;

  /// 阴影
  final BoxShadow? shadow;

  const AcrylicContainer({
    super.key,
    required this.background,
    required this.child,
    this.blurSigma = 10,
    this.borderRadius,
    this.border,
    this.padding,
    this.onBackgroundTap,
    this.overlayGradient,
    this.autoThemeOverlay = true,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 自动主题色遮罩
    final Color autoOverlayColor = isDark
        ? Colors.grey.shade800.withValues(alpha: 0.5)
        : Colors.grey.shade200.withValues(alpha: 0.5);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景层（可点击）
          Positioned.fill(
            child: GestureDetector(
              onTap: onBackgroundTap,
              child: background,
            ),
          ),

          // 模糊层
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  gradient: overlayGradient,
                  color: overlayGradient == null && autoThemeOverlay
                      ? autoOverlayColor
                      : null,
                  borderRadius: borderRadius,
                  border: border,
                  boxShadow: shadow != null ? [shadow!] : null,
                ),
                padding: padding,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
