import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 消息数量徽章组件
///
/// 用于显示未读消息数量，支持数字和红点两种模式。
/// 当 count 变化时，徽章会执行一个弹入动画（缩放 + 弹性效果）。
class VibratingBadge extends StatefulWidget {
  /// 消息数量
  final int count;

  /// 是否显示为纯红点模式
  final bool isDot;

  /// 徽章背景色（默认取 [ColorScheme.error]）
  final Color? color;

  /// 徽章文字颜色（默认取 [ColorScheme.onError]）
  final Color? textColor;

  /// 基础尺寸
  final double size;

  /// 边框颜色（默认取 [ColorScheme.surface]；传 [Colors.transparent] 可去掉描边）
  final Color? borderColor;

  const VibratingBadge({
    super.key,
    this.count = 0,
    this.isDot = false,
    this.color,
    this.textColor,
    this.size = 18.0,
    this.borderColor,
  });

  @override
  State<VibratingBadge> createState() => _VibratingBadgeState();
}

class _VibratingBadgeState extends State<VibratingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // 弹性曲线：从 0 到 1.2 再回弹到 1.0
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // 弹性效果
    );
    // 如果初始 count > 0 或红点模式，执行入场动画
    if (_shouldShow()) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(VibratingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 count 变化且新值需要显示时，触发动画（重新播放）
    if (widget.count != oldWidget.count && _shouldShow()) {
      _controller.reset();
      _controller.forward();
    }
    // 如果变为隐藏，也可以重置动画（可选）
    if (!_shouldShow() && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldShow() {
    return widget.count > 0 || widget.isDot;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow()) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final badgeColor = widget.color ?? cs.error;
    final badgeTextColor = widget.textColor ?? cs.onError;
    final borderColor = widget.borderColor ?? cs.surface;

    Widget badgeChild;
    if (widget.isDot) {
      badgeChild = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
      );
    } else {
      final String text = widget.count > 99 ? '99+' : widget.count.toString();
      final bool isSingleDigit = text.length == 1;
      badgeChild = Container(
        height: widget.size,
        width: isSingleDigit ? widget.size : null,
        constraints: isSingleDigit
            ? null
            : BoxConstraints(minWidth: widget.size),
        padding: isSingleDigit
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          shape: isSingleDigit ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isSingleDigit ? null : BorderRadius.circular(RadiusToken.pill),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            text,
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 使用 ScaleTransition 实现缩放动画
    return ScaleTransition(scale: _scaleAnimation, child: badgeChild);
  }
}
