import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Google 彩色 G 标识（CustomPainter 自绘，无需外部图片资源）。
///
/// 按官方四色（红/黄/绿/蓝）分段描画圆环 + 右侧横条，小尺寸下依然清晰。
class GoogleGIcon extends StatelessWidget {
  final double size;

  const GoogleGIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  // 官方品牌色。
  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // 环粗：与真实标识比例接近（约 0.4R）。
    final stroke = radius * 0.42;
    final ringRect = Rect.fromCircle(
      center: center,
      radius: radius - stroke / 2,
    );

    Paint segment(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // 四段弧首尾相接（canvas 角度：0=正东，顺时针为正）：
    // 红（顶部大段）→ 蓝（右下小段）→ 绿（底部）→ 黄（左侧）。
    const redStart = -2.18;
    const redSweep = 2.79;
    const blueSweep = 0.79;
    const greenSweep = 1.31;
    final blueStart = redStart + redSweep;
    final greenStart = blueStart + blueSweep;
    final yellowStart = greenStart + greenSweep;
    final yellowSweep = 2 * math.pi - redSweep - blueSweep - greenSweep;

    canvas.drawArc(ringRect, redStart, redSweep, false, segment(_red));
    canvas.drawArc(ringRect, blueStart, blueSweep, false, segment(_blue));
    canvas.drawArc(ringRect, greenStart, greenSweep, false, segment(_green));
    canvas.drawArc(ringRect, yellowStart, yellowSweep, false, segment(_yellow));

    // 蓝色横条：从圆心向右延伸至外缘。
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - stroke / 2,
        radius - stroke / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
