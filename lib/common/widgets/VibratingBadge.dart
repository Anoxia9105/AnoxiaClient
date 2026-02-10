import 'package:flutter/material.dart';

class VibratingBadge extends StatelessWidget {
  /// 消息数量
  final int count;

  /// 是否显示为纯红点（无数字）
  final bool isDot;

  /// 徽章背景色
  final Color color;

  /// 徽章文字颜色
  final Color textColor;

  /// 基础尺寸（红点的大小，或者数字圆形的高度/直径）
  final double size;

  /// 边框颜色（为了适配不同背景，通常设为白色或透明）
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
    // 0. 数量为 0 且不是红点模式时隐藏
    if (count <= 0 && !isDot) {
      return const SizedBox.shrink();
    }

    // --- 1. 纯红点模式 ---
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

    // --- 2. 数字模式 ---
    final String text = count > 99 ? '99+' : count.toString();

    // 判断是否为单字符（只有单字符时强制为正圆）
    final bool isSingleDigit = text.length == 1;

    return Container(
      // 核心修改：如果是单数字，宽高锁死为 size；如果是多数字，高度固定，宽度自适应
      height: size,
      width: isSingleDigit ? size : null,
      constraints: isSingleDigit
          ? null
          : BoxConstraints(minWidth: size), // 多位数时最小宽度也是 size
      // 核心修改：单数字不需要 padding，多数字需要左右撑开
      padding: isSingleDigit
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 6),

      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        // 单数字用圆形，多数字用圆角矩形
        shape: isSingleDigit ? BoxShape.circle : BoxShape.rectangle,
        // 多数字时的圆角，设大一点（如 100）能确保两头是半圆
        borderRadius: isSingleDigit ? null : BorderRadius.circular(100),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10, // 字体略微调小保证在小圆圈内不拥挤
          fontWeight: FontWeight.bold,
          height: 1.0, // 关键：设置为 1.0 移除文字自带的行高边距，便于绝对居中
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
