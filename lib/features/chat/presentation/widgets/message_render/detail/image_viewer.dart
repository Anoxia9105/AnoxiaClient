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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachment.url == null || widget.attachment.url!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Text(
              'image_load_failed'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              icon: HugeIcons.strokeRoundedZoomInArea,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedZoomOutArea,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _controller.scale = _controller.initial.scale,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _downloadImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 主体图片展示区
            Positioned.fill(
              child: GestureDetector(
                // 兜底关闭：errorBuilder 会替换整个 PhotoView，导致 onTapUp 失效
                // 外层套 GestureDetector 确保任何情况下点击都能关闭
                onTap: () => Navigator.pop(context),
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: PhotoView(
                    controller: _controller,
                    scaleStateController: _scaleStateCtrl,
                    onTapUp: (context, details, value) =>
                        Navigator.pop(context),
                    imageProvider: CachedNetworkImageProvider(
                      widget.attachment.url!,
                    ),
                    filterQuality: FilterQuality.high,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.5,
                    enableRotation: false,
                    basePosition: Alignment.center,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: widget.heroTag,
                    ),
                    loadingBuilder: (context, event) => _buildLoading(event),
                    errorBuilder: (context, error, stackTrace) => _buildError(),
                  ),
                ),
              ),
            ),

            // 底部文件名提示（穿透点击，不拦截关闭手势）
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      widget.attachment.name ?? 'image'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ImageChunkEvent? event) {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: event == null
              ? null
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.white54, size: 50),
          const SizedBox(height: 8),
          Text(
            'image_failed_to_load'.tr(),
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Text(
            'tap_to_close'.tr(),
            style: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
