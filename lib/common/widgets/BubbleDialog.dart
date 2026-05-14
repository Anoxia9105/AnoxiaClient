import 'dart:math';

import 'package:flutter/material.dart';

/// 气泡边框箭头属性计算结果
///
/// 用于 [BubbleShapeBorder] 中箭头路径的几何计算
class _BubbleBorderArrowProperties {
  /// 箭头宽度的一半
  final double halfWidth;

  /// 箭头斜边的长度
  final double hypotenuse;

  /// 斜边在主轴上的投影
  final double projectionOnMain;

  /// 斜边在纵轴上的投影
  final double projectionOnCross;

  /// 箭头半径在主轴上的投影
  final double arrowProjectionOnMain;

  /// 箭头尖端的投影长度
  final double topLen;

  _BubbleBorderArrowProperties({
    required this.halfWidth,
    required this.hypotenuse,
    required this.projectionOnMain,
    required this.projectionOnCross,
    required this.arrowProjectionOnMain,
    required this.topLen,
  });
}

/// 气泡形状边框
///
/// 支持在任意方向绘制箭头，常用于聊天气泡。
class BubbleShapeBorder extends OutlinedBorder {
  /// 圆角半径
  final BorderRadius borderRadius;

  /// 箭头方向
  final AxisDirection arrowDirection;

  /// 箭头长度
  final double arrowLength;

  /// 箭头宽度
  final double arrowWidth;

  /// 箭头圆角
  final double arrowRadius;

  /// 箭头偏移（默认居中）
  final double? arrowOffset;

  /// 填充颜色
  final Color? fillColor;

  const BubbleShapeBorder({
    super.side,
    required this.arrowDirection,
    this.borderRadius = BorderRadius.zero,
    this.arrowLength = 12,
    this.arrowWidth = 18,
    this.arrowRadius = 3,
    this.arrowOffset,
    this.fillColor,
  });

  @override
  OutlinedBorder copyWith({
    AxisDirection? arrowDirection,
    BorderSide? side,
    BorderRadius? borderRadius,
    double? arrowLength,
    double? arrowWidth,
    double? arrowRadius,
    double? arrowOffset,
    Color? fillColor,
  }) {
    return BubbleShapeBorder(
      arrowDirection: arrowDirection ?? this.arrowDirection,
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      arrowLength: arrowLength ?? this.arrowLength,
      arrowWidth: arrowWidth ?? this.arrowWidth,
      arrowRadius: arrowRadius ?? this.arrowRadius,
      arrowOffset: arrowOffset ?? this.arrowOffset,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  /// 计算箭头几何属性
  _BubbleBorderArrowProperties _calculateArrowProperties() {
    final arrowHalfWidth = arrowWidth / 2;
    final double hypotenuse = sqrt(
      arrowLength * arrowLength + arrowHalfWidth * arrowHalfWidth,
    );
    final double projectionOnMain = arrowHalfWidth * arrowRadius / hypotenuse;
    final double projectionOnCross =
        projectionOnMain * arrowLength / arrowHalfWidth;
    final double arrowProjectionOnMain = arrowLength * arrowRadius / hypotenuse;
    final double pointArrowTopLen =
        arrowProjectionOnMain * arrowLength / arrowHalfWidth;
    return _BubbleBorderArrowProperties(
      halfWidth: arrowHalfWidth,
      hypotenuse: hypotenuse,
      projectionOnMain: projectionOnMain,
      projectionOnCross: projectionOnCross,
      arrowProjectionOnMain: arrowProjectionOnMain,
      topLen: pointArrowTopLen,
    );
  }

  /// 构建气泡路径
  Path _buildPath(Rect rect) {
    final path = Path();
    EdgeInsets padding = EdgeInsets.zero;
    if (arrowDirection == AxisDirection.up) {
      padding = EdgeInsets.only(top: arrowLength);
    } else if (arrowDirection == AxisDirection.right) {
      padding = EdgeInsets.only(right: arrowLength);
    } else if (arrowDirection == AxisDirection.down) {
      padding = EdgeInsets.only(bottom: arrowLength);
    } else if (arrowDirection == AxisDirection.left) {
      padding = EdgeInsets.only(left: arrowLength);
    }
    final nRect = Rect.fromLTRB(
      rect.left + padding.left,
      rect.top + padding.top,
      rect.right - padding.right,
      rect.bottom - padding.bottom,
    );

    final arrowProp = _calculateArrowProperties();
    final startPoint = Offset(nRect.left + borderRadius.topLeft.x, nRect.top);

    path.moveTo(startPoint.dx, startPoint.dy);

    // 绘制上箭头
    if (arrowDirection == AxisDirection.up) {
      _drawArrowTop(path, nRect, rect, arrowProp);
    }

    path.lineTo(nRect.right - borderRadius.topRight.x, nRect.top);
    path.arcToPoint(
      Offset(nRect.right, nRect.top + borderRadius.topRight.y),
      radius: borderRadius.topRight,
      rotation: 90,
    );

    // 绘制右箭头
    if (arrowDirection == AxisDirection.right) {
      _drawArrowRight(path, nRect, rect, arrowProp);
    }

    path.lineTo(nRect.right, nRect.bottom - borderRadius.bottomRight.y);
    path.arcToPoint(
      Offset(nRect.right - borderRadius.bottomRight.x, nRect.bottom),
      radius: borderRadius.bottomRight,
      rotation: 90,
    );

    // 绘制下箭头
    if (arrowDirection == AxisDirection.down) {
      _drawArrowBottom(path, nRect, rect, arrowProp);
    }

    path.lineTo(nRect.left + borderRadius.bottomLeft.x, nRect.bottom);
    path.arcToPoint(
      Offset(nRect.left, nRect.bottom - borderRadius.bottomRight.y),
      radius: borderRadius.bottomLeft,
      rotation: 90,
    );

    // 绘制左箭头
    if (arrowDirection == AxisDirection.left) {
      _drawArrowLeft(path, nRect, rect, arrowProp);
    }

    path.lineTo(nRect.left, nRect.top + borderRadius.topLeft.y);
    path.arcToPoint(startPoint, radius: borderRadius.topLeft, rotation: 90);

    return path;
  }

  void _drawArrowTop(Path path, Rect nRect, Rect rect, _BubbleBorderArrowProperties arrowProp) {
    Offset pointCenter = Offset(
      nRect.left + (arrowOffset ?? nRect.width / 2),
      nRect.top,
    );
    Offset pointStart = Offset(pointCenter.dx - arrowProp.halfWidth, nRect.top);
    Offset pointArrow = Offset(pointCenter.dx, rect.top);
    Offset pointEnd = Offset(pointCenter.dx + arrowProp.halfWidth, nRect.top);

    path.lineTo(pointStart.dx - arrowRadius, pointStart.dy);
    path.quadraticBezierTo(
      pointStart.dx, pointStart.dy,
      pointStart.dx + arrowProp.projectionOnMain, pointStart.dy - arrowProp.projectionOnCross,
    );

    path.lineTo(pointArrow.dx - arrowProp.arrowProjectionOnMain, pointArrow.dy + arrowProp.topLen);
    path.quadraticBezierTo(
      pointArrow.dx, pointArrow.dy,
      pointArrow.dx + arrowProp.arrowProjectionOnMain, pointArrow.dy + arrowProp.topLen,
    );

    path.lineTo(pointEnd.dx - arrowProp.projectionOnMain, pointEnd.dy - arrowProp.projectionOnCross);
    path.quadraticBezierTo(
      pointEnd.dx, pointEnd.dy,
      pointEnd.dx + arrowRadius, pointEnd.dy,
    );
  }

  void _drawArrowRight(Path path, Rect nRect, Rect rect, _BubbleBorderArrowProperties arrowProp) {
    Offset pointCenter = Offset(
      nRect.right,
      nRect.top + (arrowOffset ?? nRect.height / 2),
    );
    Offset pointStart = Offset(nRect.right, pointCenter.dy - arrowProp.halfWidth);
    Offset pointArrow = Offset(rect.right, pointCenter.dy);
    Offset pointEnd = Offset(nRect.right, pointCenter.dy + arrowProp.halfWidth);

    path.lineTo(pointStart.dx, pointStart.dy - arrowRadius);
    path.quadraticBezierTo(
      pointStart.dx, pointStart.dy,
      pointStart.dx + arrowProp.projectionOnCross, pointStart.dy + arrowProp.projectionOnMain,
    );

    path.lineTo(pointArrow.dx - arrowProp.topLen, pointArrow.dy - arrowProp.arrowProjectionOnMain);
    path.quadraticBezierTo(
      pointArrow.dx, pointArrow.dy,
      pointArrow.dx - arrowProp.topLen, pointArrow.dy + arrowProp.arrowProjectionOnMain,
    );

    path.lineTo(pointEnd.dx + arrowProp.projectionOnCross, pointEnd.dy - arrowProp.projectionOnMain);
    path.quadraticBezierTo(
      pointEnd.dx, pointEnd.dy,
      pointEnd.dx, pointEnd.dy + arrowRadius,
    );
  }

  void _drawArrowBottom(Path path, Rect nRect, Rect rect, _BubbleBorderArrowProperties arrowProp) {
    Offset pointCenter = Offset(
      nRect.left + (arrowOffset ?? nRect.width / 2),
      nRect.bottom,
    );
    Offset pointStart = Offset(pointCenter.dx + arrowProp.halfWidth, nRect.bottom);
    Offset pointArrow = Offset(pointCenter.dx, rect.bottom);
    Offset pointEnd = Offset(pointCenter.dx - arrowProp.halfWidth, nRect.bottom);

    path.lineTo(pointStart.dx + arrowRadius, pointStart.dy);
    path.quadraticBezierTo(
      pointStart.dx, pointStart.dy,
      pointStart.dx - arrowProp.projectionOnMain, pointStart.dy + arrowProp.projectionOnCross,
    );

    path.lineTo(pointArrow.dx + arrowProp.arrowProjectionOnMain, pointArrow.dy - arrowProp.topLen);
    path.quadraticBezierTo(
      pointArrow.dx, pointArrow.dy,
      pointArrow.dx - arrowProp.arrowProjectionOnMain, pointArrow.dy - arrowProp.topLen,
    );

    path.lineTo(pointEnd.dx + arrowProp.projectionOnMain, pointEnd.dy + arrowProp.projectionOnCross);
    path.quadraticBezierTo(
      pointEnd.dx, pointEnd.dy,
      pointEnd.dx - arrowRadius, pointEnd.dy,
    );
  }

  void _drawArrowLeft(Path path, Rect nRect, Rect rect, _BubbleBorderArrowProperties arrowProp) {
    Offset pointCenter = Offset(
      nRect.left,
      nRect.top + (arrowOffset ?? nRect.height / 2),
    );
    Offset pointStart = Offset(nRect.left, pointCenter.dy + arrowProp.halfWidth);
    Offset pointArrow = Offset(rect.left, pointCenter.dy);
    Offset pointEnd = Offset(nRect.left, pointCenter.dy - arrowProp.halfWidth);

    path.lineTo(pointStart.dx, pointStart.dy + arrowRadius);
    path.quadraticBezierTo(
      pointStart.dx, pointStart.dy,
      pointStart.dx - arrowProp.projectionOnCross, pointStart.dy - arrowProp.projectionOnMain,
    );

    path.lineTo(pointArrow.dx + arrowProp.topLen, pointArrow.dy + arrowProp.arrowProjectionOnMain);
    path.quadraticBezierTo(
      pointArrow.dx, pointArrow.dy,
      pointArrow.dx + arrowProp.topLen, pointArrow.dy - arrowProp.arrowProjectionOnMain,
    );

    path.lineTo(pointEnd.dx - arrowProp.projectionOnCross, pointEnd.dy + arrowProp.projectionOnMain);
    path.quadraticBezierTo(
      pointEnd.dx, pointEnd.dy,
      pointEnd.dx, pointEnd.dy - arrowRadius,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (fillColor == null && side == BorderSide.none) return;

    final path = _buildPath(rect);
    final Paint paint = Paint()
      ..color = side.color
      ..style = PaintingStyle.stroke;

    if (fillColor != null) {
      paint.color = fillColor!;
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
    if (side != BorderSide.none) {
      paint.color = side.color;
      paint.strokeWidth = side.width;
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return BubbleShapeBorder(
      arrowDirection: arrowDirection,
      side: side.scale(t),
      borderRadius: borderRadius * t,
      arrowLength: arrowLength * t,
      arrowWidth: arrowWidth * t,
      arrowRadius: arrowRadius * t,
      arrowOffset: (arrowOffset ?? 0) * t,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is BubbleShapeBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.arrowLength == arrowLength &&
        other.arrowWidth == arrowWidth &&
        other.arrowRadius == arrowRadius &&
        other.arrowDirection == arrowDirection &&
        other.arrowOffset == arrowOffset &&
        other.fillColor == fillColor;
  }

  @override
  int get hashCode => Object.hash(
    side, borderRadius, arrowLength, arrowWidth, arrowRadius,
    arrowDirection, arrowOffset, fillColor,
  );
}

/// 气泡组件
///
/// 快速创建带箭头的气泡容器。
class BubbleWidget extends StatelessWidget {
  final BorderSide border;
  final AxisDirection arrowDirection;
  final BorderRadius? borderRadius;
  final double arrowLength;
  final double arrowWidth;
  final double? arrowOffset;
  final double arrowRadius;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final WidgetBuilder contentBuilder;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? margin;

  const BubbleWidget({
    super.key,
    required this.arrowDirection,
    this.arrowOffset,
    required this.contentBuilder,
    this.border = BorderSide.none,
    this.borderRadius,
    this.arrowLength = 10,
    this.arrowWidth = 17,
    this.arrowRadius = 3,
    this.backgroundColor,
    this.shadows,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets bubblePadding = EdgeInsets.zero;
    if (arrowDirection == AxisDirection.up) {
      bubblePadding = EdgeInsets.only(top: arrowLength);
    } else if (arrowDirection == AxisDirection.down) {
      bubblePadding = EdgeInsets.only(bottom: arrowLength);
    } else if (arrowDirection == AxisDirection.left) {
      bubblePadding = EdgeInsets.only(left: arrowLength);
    } else if (arrowDirection == AxisDirection.right) {
      bubblePadding = EdgeInsets.only(right: arrowLength);
    }

    return Container(
      margin: margin,
      decoration: ShapeDecoration(
        shape: BubbleShapeBorder(
          side: border,
          arrowDirection: arrowDirection,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          arrowLength: arrowLength,
          arrowWidth: arrowWidth,
          arrowRadius: arrowRadius,
          arrowOffset: arrowOffset,
          fillColor: backgroundColor ?? Colors.white,
        ),
        shadows: shadows,
      ),
      child: Padding(
        padding: bubblePadding.add(padding ?? EdgeInsets.zero),
        child: contentBuilder(context),
      ),
    );
  }
}
