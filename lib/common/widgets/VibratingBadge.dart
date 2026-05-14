import 'package:flutter/material.dart';

/// 消息数量徽章组件
///
/// 用于显示未读消息数量，支持数字和红点两种模式。
class VibratingBadge extends StatelessWidget {
  /// 消息数量
  final int count;

  /// 是否显示为纯红点模式
  final bool isDot;

  /// 徽章背景色
  final Color color;

  /// 徽章文字颜色
  final Color textColor;

  /// 基础尺寸
  final double size;

  /// 边框颜色
  final Color? borderColor;

  const VibratingBadge({
    super.key,
    this.count = 0,
    this.isDot = false,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.size = 18.0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // 数量为 0 且非红点模式时隐藏
    if (count <= 0 && !isDot) {
      return const SizedBox.shrink();
    }

    // 红点模式
    if (isDot) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
      );
    }

    // 数字模式
    final String text = count > 99 ? '99+' : count.toString();
    final bool isSingleDigit = text.length == 1;

    return Container(
      height: size,
      width: isSingleDigit ? size : null,
      constraints: isSingleDigit
          ? null
          : BoxConstraints(minWidth: size),
      padding: isSingleDigit
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: isSingleDigit ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isSingleDigit ? null : BorderRadius.circular(100),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
