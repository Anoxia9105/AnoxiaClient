import 'package:flutter/material.dart';

/// 徽章：支持数字显示和纯红点模式
class VibratingBadge extends StatelessWidget {
  final int messageCount;
  final double width;
  final double height;

  /// 是否显示为纯红点（无数字）
  final bool isDot;

  const VibratingBadge({
    super.key,
    required this.messageCount,
    this.width = 18,
    this.height = 18,
    this.isDot = false, // 默认显示数字
  });

  @override
  Widget build(BuildContext context) {
    // 数量为 0 时直接消失
    if (messageCount == 0) {
      return const SizedBox.shrink();
    }

    // 计算红点的实际尺寸
    // 如果是 isDot 模式，红点固定为一个较小的尺寸
    final double actualWidth = isDot ? 10 : width;
    final double actualHeight = isDot ? 10 : height;

    return Container(
      width: actualWidth,
      height: actualHeight,
      // 数字模式需要边距，点模式不需要
      padding: isDot ? null : const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade600, // 亮一点的红色更醒目
        borderRadius: BorderRadius.circular(actualHeight / 2),
        // 增加白色边框，在深色/彩色背景下更清晰（可选）
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: isDot
          ? null // 点模式下不显示文字
          : FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          messageCount > 99 ? '99+' : messageCount.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold, // 加粗更易读
            // 桌面端显示时防止字体被缩放得太奇怪
            height: 1.2,
          ),
        ),
      ),
    );
  }
}