import 'package:flutter/material.dart';

class VolumeIndicator extends StatelessWidget {
  final double volume; // 0.0 - 1.0
  final int barCount;

  const VolumeIndicator({super.key, required this.volume, this.barCount = 12});

  @override
  Widget build(BuildContext context) {
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
