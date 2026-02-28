import 'package:flutter/material.dart';

class VolumeIndicator extends StatelessWidget {
  final double volume;  // 0.0 - 1.0
  final double size;
  
  const VolumeIndicator({
    required this.volume,
    this.size = 60,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size / 4,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: VolumePainter(volume: volume),
      ),
    );
  }
}

class VolumePainter extends CustomPainter {
  final double volume;
  
  VolumePainter({required this.volume});
  
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final bgPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );
    
    // 绘制音量条
    final volumePaint = Paint()
      ..color = Color.lerp(
        Colors.green,
        Colors.red,
        volume.clamp(0, 1),
      )!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * volume, size.height),
      volumePaint,
    );
  }
  
  @override
  bool shouldRepaint(VolumePainter oldDelegate) {
    return oldDelegate.volume != volume;
  }
}
