import 'package:flutter/material.dart';

/// 徽章
class VibratingBadge extends StatelessWidget {
  final int messageCount;
  final double width;
  final double height;
  const VibratingBadge({
    super.key,
    required this.messageCount,
    this.width = 20,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (messageCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          messageCount > 99 ? '99+' : messageCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
