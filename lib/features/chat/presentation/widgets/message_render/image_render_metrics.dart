import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../../framework/protocol/message/attachment.dart';

const double imageMessageMaxWidth = 320;
const double imageMessageMaxHeight = 320;

/// Resolves the logical size of a single image message from its protocol
/// pixel dimensions while preserving its aspect ratio (等比缩放).
Size resolveImageMessageDisplaySize(
  Attachment attachment, {
  double maxWidth = imageMessageMaxWidth,
  double maxHeight = imageMessageMaxHeight,
  double? intrinsicWidth,
  double? intrinsicHeight,
}) {
  final rawWidth = attachment.width?.toDouble() ?? intrinsicWidth;
  final rawHeight = attachment.height?.toDouble() ?? intrinsicHeight;
  if (rawWidth == null ||
      rawHeight == null ||
      rawWidth <= 0 ||
      rawHeight <= 0) {
    return Size(maxWidth, maxHeight * 0.75);
  }

  // 等比缩放：取宽、高两个维度中更小的缩放比，且仅缩小不放大
  final widthRatio = maxWidth / rawWidth;
  final heightRatio = maxHeight / rawHeight;
  final scale = math.min(1.0, math.min(widthRatio, heightRatio));
  // 保持原始宽高比，避免拉伸
  return Size(rawWidth * scale, rawHeight * scale);
}

/// Converts a desktop mouse-wheel delta into the next image viewer scale.
///
/// Desktop convention: scrolling upward (negative Y) zooms in and scrolling
/// downward (positive Y) zooms out. A null controller scale starts from the
/// image's actual initial fitted scale rather than an incorrect hard-coded 1.0.
double imageViewerScaleForScroll({
  required double? currentScale,
  required double initialScale,
  required double scrollDeltaY,
  double step = 0.2,
  double minScale = 0.5,
  double maxScale = 4,
}) {
  final scale = currentScale ?? initialScale;
  if (scrollDeltaY == 0) {
    return scale.clamp(minScale, maxScale).toDouble();
  }
  final factor = scrollDeltaY < 0 ? 1 + step : 1 - step;
  return (scale * factor).clamp(minScale, maxScale).toDouble();
}
