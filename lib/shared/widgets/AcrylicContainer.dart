import 'dart:ui';
import 'package:flutter/material.dart';

/// 增强版 AcrylicContainer
/// - 支持亮/暗模式自动配色
/// - 支持渐变叠加
/// - 支持点击背景刷新
/// - 支持阴影
class AcrylicContainer extends StatelessWidget {
  final Widget background; // 背景（图片/渐变等）
  final double blurSigma; // 模糊强度
  final BorderRadius? borderRadius; // 圆角
  final BoxBorder? border; // 边框
  final EdgeInsetsGeometry? padding; // 内边距
  final Widget child; // 内容
  final VoidCallback? onBackgroundTap; // 点击背景回调
  final Gradient? overlayGradient; // 渐变叠加
  final bool autoThemeOverlay; // 是否自动根据主题生成 overlay
  final BoxShadow? shadow; // 阴影

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

    // 自动主题色 overlay
    final Color autoOverlayColor = isDark
        ? Colors.grey.shade800.withOpacity(0.5)
        : Colors.grey.shade200.withOpacity(0.5);

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
                  // 如果有渐变优先用渐变，否则用自动主题色
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
