import 'package:flutter/material.dart';

/// 音量指示器组件
///
/// 以柱状图形式展示音量大小，颜色从绿色渐变到红色
class VolumeIndicator extends StatelessWidget {
  /// 当前音量值（0.0 - 1.0）
  final double volume;

  /// 柱状条数量
  final int barCount;

  const VolumeIndicator({super.key, required this.volume, this.barCount = 12});

  @override
  Widget build(BuildContext context) {
    // 音量过小时不显示
    if (volume < 0.01) return const SizedBox.shrink();

    final activeCount = (volume.clamp(0.0, 1.0) * barCount).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (i) {
        final active = i < activeCount;
        final height = 8.0; // 固定高度，保证每根柱子高度一致

        return Container(
          width: 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            // 激活的柱子颜色从绿色渐变到红色
            color: active
                ? Color.lerp(Colors.greenAccent, Colors.redAccent, i / barCount)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
