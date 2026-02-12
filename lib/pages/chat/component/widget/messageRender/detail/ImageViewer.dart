import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatefulWidget {
  final Attachment attachment;
  final String heroTag;

  const ImageViewer({
    required this.attachment,
    required this.heroTag,
    super.key,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PhotoViewController _controller;
  late final PhotoViewScaleStateController _scaleStateCtrl;

  // 缩放因子控制
  static const double _step = 0.2;
  static const double _minScaleFactor = 0.5;
  static const double _maxScaleFactor = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _scaleStateCtrl = PhotoViewScaleStateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateCtrl.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent evt) {
    if (evt is PointerScrollEvent) {
      final double oldScale = _controller.scale ?? 1.0;
      final double delta = evt.scrollDelta.dy < 0 ? (1 + _step) : (1 - _step);
      final double target = (oldScale * delta).clamp(
        _minScaleFactor,
        _maxScaleFactor,
      );
      _controller.scale = target;
    }
  }

  void _zoomIn() {
    final double oldScale = _controller.scale ?? 1.0;
    final double target = (oldScale * (1 + _step)).clamp(
      _minScaleFactor,
      _maxScaleFactor,
    );
    _controller.scale = target;
  }

  void _zoomOut() {
    final double oldScale = _controller.scale ?? 1.0;
    final double target = (oldScale * (1 - _step)).clamp(
      _minScaleFactor,
      _maxScaleFactor,
    );
    _controller.scale = target;
  }

  void _downloadImage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('image_download_started'.tr())));

    // DioClient().download(urlPath, savePath)
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachment.url == null || widget.attachment.url!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('image_load_failed'.tr(), style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft02,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedZoomInArea,
              color: Colors.white,
              size: 16,
            ),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedZoomOutArea,
              color: Colors.white,
              size: 16,
            ),
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Colors.white,
              size: 16,
            ),
            tooltip: '重置缩放',
            onPressed: () {
              // 重置时也回到 contained 状态
              _controller.scale = _controller.initial.scale;
            },
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
              color: Colors.white,
              size: 16,
            ),
            onPressed: _downloadImage,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 中心图片区域
            Positioned.fill(
              // 使用 Positioned.fill 确保占满全屏
              child: Listener(
                onPointerSignal: _onPointerSignal,
                child: PhotoView(
                  controller: _controller,
                  scaleStateController: _scaleStateCtrl,
                  imageProvider: CachedNetworkImageProvider(
                    widget.attachment.url!,
                  ),
                  // 背景设为透明或黑，防止缩小时看到白底
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),

                  // 初始缩放为“包含”，即等比缩放至能看到全图
                  initialScale: PhotoViewComputedScale.contained,

                  //  最小缩放：允许稍微比全屏小一点，增加阻尼感
                  minScale: PhotoViewComputedScale.contained * 0.8,

                  //  最大缩放：允许放大到覆盖屏幕的 2.5 倍
                  maxScale: PhotoViewComputedScale.covered * 2.5,

                  enableRotation: false,
                  basePosition: Alignment.center,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),

                  // 添加加载指示器，大图加载时体验更好
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: event == null
                            ? null
                            : event.cumulativeBytesLoaded /
                                  (event.expectedTotalBytes ?? 1),
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // 添加错误处理
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 50,
                        ),
                        const SizedBox(height: 8),
                        Text('image_failed_to_load'.tr(), style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 底部文件名 (保持不变)
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    widget.attachment.name ?? '图像',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
