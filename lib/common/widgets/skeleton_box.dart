import 'package:flutter/material.dart';

/// 骨架屏加载占位块
///
/// 用于内容加载中时的占位展示，通过闪烁动画模拟加载效果。
/// 支持矩形、圆形、自定义尺寸和边距。
class SkeletonBox extends StatefulWidget {
  /// 宽度（null 时自适应）
  final double? width;

  /// 高度（null 时自适应）
  final double? height;

  /// 圆角半径
  final double radius;

  /// 是否为圆形
  final bool circle;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.circle = false,
    this.margin,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final glow = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.75);

    final child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = (_controller.value * 2) - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.2 + shift, -0.2),
              end: Alignment(-0.2 + shift, 0.2),
              colors: [base, glow, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: widget.circle
                  ? null
                  : BorderRadius.circular(widget.radius),
              shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        );
      },
    );

    return widget.margin == null
        ? child
        : Container(margin: widget.margin, child: child);
  }
}

/// 骨架屏线条组件
///
/// 简化的骨架块，专用于文本行的占位展示。
class SkeletonLine extends StatelessWidget {
  /// 宽度
  final double width;

  /// 高度
  final double height;

  /// 圆角半径
  final double radius;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    required this.width,
    this.height = 12,
    this.radius = 999,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      radius: radius,
      margin: margin,
    );
  }
}
