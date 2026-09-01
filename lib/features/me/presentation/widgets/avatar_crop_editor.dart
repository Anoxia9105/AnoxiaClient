import 'dart:math' as math;
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:anoxia/framework/theme/radius_token.dart';

/// 头像裁剪编辑器（纯 Flutter 实现，全平台可用，含 Web/Wasm）
///
/// 提供方形裁剪预览：
/// - 拖动平移 / 双指或鼠标滚轮缩放，图片始终覆盖裁剪区域
/// - [cropSquare] 按当前可视区域裁剪出正方形头像（使用纯 Dart 图像处理，Web/Wasm 兼容）
class AvatarCropEditor extends StatefulWidget {
  const AvatarCropEditor({
    super.key,
    required this.imageBytes,
    this.size = 300,
    this.outputSize = 512,
  });

  /// 原始图片字节
  final Uint8List imageBytes;

  /// 裁剪预览区边长（正方形）
  final double size;

  /// 裁剪输出尺寸（正方形边长，像素）
  final int outputSize;

  @override
  State<AvatarCropEditor> createState() => AvatarCropEditorState();
}

class AvatarCropEditorState extends State<AvatarCropEditor> {
  /// 用于裁剪的解码图片（大图先降采样，限制内存占用）
  img.Image? _decoded;

  /// 用于预览显示的图片字节
  Uint8List? _displayBytes;

  bool _loading = true;
  bool _failed = false;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _gestureStartScale = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  static const double _minScale = 1.0;
  static const double _maxScale = 6.0;
  static const double _maxSide = 2048.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvatarCropEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _scale = 1.0;
      _offset = Offset.zero;
      _loading = true;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final decoded = img.decodeImage(widget.imageBytes);
      if (decoded == null) {
        throw StateError('decode failed');
      }
      img.Image image = decoded;
      final maxSide = math.max(image.width, image.height);
      if (maxSide > _maxSide) {
        final ratio = _maxSide / maxSide;
        image = img.copyResize(
          image,
          width: (image.width * ratio).round(),
          height: (image.height * ratio).round(),
          interpolation: img.Interpolation.linear,
        );
      }
      if (!mounted) return;
      setState(() {
        _decoded = image;
        _displayBytes = img.encodePng(image);
        _scale = 1.0;
        _offset = _centeredOffset(image.width, image.height);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// 计算缩放为 1 时的显示尺寸（cover 填充预览区）
  (double, double) _baseSize() {
    final decoded = _decoded!;
    final s = widget.size;
    final aspect = decoded.width / decoded.height;
    if (aspect >= 1) {
      return (s * aspect, s);
    }
    return (s, s / aspect);
  }

  /// 缩放为 1 时把图片居中放置的偏移量
  Offset _centeredOffset(int imgW, int imgH) {
    final s = widget.size;
    final aspect = imgW / imgH;
    final baseW = aspect >= 1 ? s * aspect : s;
    final baseH = aspect >= 1 ? s : s / aspect;
    return Offset((s - baseW) / 2, (s - baseH) / 2);
  }

  /// 获取当前裁剪区域对应的显示偏移（限制图片始终覆盖预览区）
  (double, double) _clampedOffset(double baseW, double baseH) {
    final s = widget.size;
    final idxW = baseW * _scale;
    final idxH = baseH * _scale;
    final dx = _offset.dx.clamp(s - idxW, 0.0).toDouble();
    final dy = _offset.dy.clamp(s - idxH, 0.0).toDouble();
    return (dx, dy);
  }

  /// 按当前可视区域裁剪出正方形头像
  ///
  /// 返回裁剪后的 JPG 字节；失败返回 null。
  Uint8List? cropSquare() {
    final decoded = _decoded;
    if (decoded == null || _loading || _failed) return null;

    final (baseW, baseH) = _baseSize();
    final (dx, dy) = _clampedOffset(baseW, baseH);
    final s = widget.size;

    final idxW = baseW * _scale;
    final idxH = baseH * _scale;
    final factorX = decoded.width / idxW;
    final factorY = decoded.height / idxH;

    final x = (-dx * factorX).round().clamp(0, decoded.width - 1);
    final y = (-dy * factorY).round().clamp(0, decoded.height - 1);
    final w = math.min((s * factorX).round(), decoded.width - x);
    final h = math.min((s * factorY).round(), decoded.height - y);
    if (w <= 0 || h <= 0) return null;

    try {
      var cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      if (cropped.width != widget.outputSize ||
          cropped.height != widget.outputSize) {
        cropped = img.copyResize(
          cropped,
          width: widget.outputSize,
          height: widget.outputSize,
          interpolation: img.Interpolation.cubic,
        );
      }
      return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
    } catch (_) {
      return null;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
    _gestureStartOffset = _offset;
    _gestureStartFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_gestureStartScale * details.scale)
          .clamp(_minScale, _maxScale)
          .toDouble();
      _offset = _gestureStartOffset +
          (details.localFocalPoint - _gestureStartFocal);
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final factor = event.scrollDelta.dy < 0 ? 1.15 : (1 / 1.15);
    setState(() {
      final newScale =
          (_scale * factor).clamp(_minScale, _maxScale).toDouble();
      if (newScale == _scale) return;
      final ratio = newScale / _scale;
      final point = event.localPosition;
      _scale = newScale;
      _offset = point - (point - _offset) * ratio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_failed) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text(
            'me_avatar_load_failed'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    if (_loading) {
      return SizedBox(
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = widget.size;
    final (baseW, baseH) = _baseSize();
    final (dx, dy) = _clampedOffset(baseW, baseH);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerSignal: _onPointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.xl),
              child: SizedBox(
                width: s,
                height: s,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: dx,
                      top: dy,
                      child: Image.memory(
                        _displayBytes!,
                        width: baseW * _scale,
                        height: baseH * _scale,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CropFramePainter(
                            frameColor: cs.primary,
                            gridColor: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'me_avatar_upload_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith( color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 裁剪框网格 + 边框绘制
class _CropFramePainter extends CustomPainter {
  final Color frameColor;
  final Color gridColor;

  const _CropFramePainter({required this.frameColor, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), gridPaint);
    canvas.drawLine(Offset(w * 2 / 3, 0), Offset(w * 2 / 3, h), gridPaint);
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), gridPaint);
    canvas.drawLine(Offset(0, h * 2 / 3), Offset(w, h * 2 / 3), gridPaint);

    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, w - 2, h - 2),
        const Radius.circular(14),
      ),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropFramePainter oldDelegate) =>
      oldDelegate.frameColor != frameColor ||
      oldDelegate.gridColor != gridColor;
}
