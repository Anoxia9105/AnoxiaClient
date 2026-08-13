import 'dart:math' as math;
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/platform/shims/image_gallery_saver_plus_shim.dart';
import 'package:photo_view/photo_view.dart';

import '../image_render_metrics.dart';

/// 图片查看器组件
///
/// 提供全屏图片预览功能，支持：
/// - 默认按原图 1:1 显示，超大图等比缩放至不超出屏幕
/// - 手势缩放（双指捏合、鼠标滚轮）
/// - 放大/缩小按钮
/// - 重置缩放按钮
/// - 图片下载功能（需存储权限）
/// - Hero 动画过渡
/// - 多图切换（基于会话消息中的图片附件列表）
/// - 加载状态和错误处理
///
/// [attachment] 当前图片附件信息
/// [heroTag] Hero 动画标签，用于共享元素过渡
/// [roomId] 会话 ID，若提供则从该会话所有消息中提取图片列表实现多图浏览
/// [currentUrl] 当前显示的图片 URL，用于定位
class ImageViewer extends ConsumerStatefulWidget {
  final Attachment attachment;
  final String heroTag;
  final String? roomId;
  final String? currentUrl;

  const ImageViewer({
    required this.attachment,
    required this.heroTag,
    this.roomId,
    this.currentUrl,
    super.key,
  });

  @override
  ConsumerState<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends ConsumerState<ImageViewer> {
  // 图片控制器，管理缩放、平移等
  late final PhotoViewController _controller;
  // 缩放状态控制器（可用于动画过渡）
  late final PhotoViewScaleStateController _scaleStateCtrl;
  // 下载中标志，防止重复点击
  bool _downloading = false;
  // 当前显示的图片 URL（可能随切换变化）
  late String? _currentUrl;
  // 当前图片解码后的实际像素尺寸（用于计算原图 1:1 缩放）
  Size? _imageSize;
  // 图片尺寸监听（复用同一 ImageStream，避免重复下载）
  ImageStream? _imageSizeStream;
  ImageStreamListener? _imageSizeStreamListener;

  // 缩放步长（每次点击放大/缩小的比例因子）
  static const double _step = 0.2;
  // 最小缩放倍数
  static const double _minScaleFactor = 0.5;
  // 最大缩放倍数
  static const double _maxScaleFactor = 4.0;
  double _viewerInitialScale = 1;
  double _viewerMinScale = _minScaleFactor;
  double _viewerMaxScale = _maxScaleFactor;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _scaleStateCtrl = PhotoViewScaleStateController();
    _currentUrl = widget.currentUrl ?? widget.attachment.url;
    final url = _currentUrl;
    if (url != null && url.isNotEmpty) _loadImageSize(url);
  }

  @override
  void dispose() {
    _removeImageSizeListener();
    _controller.dispose();
    _scaleStateCtrl.dispose();
    super.dispose();
  }

  /// 监听图片解码结果，获取图片实际像素尺寸
  void _loadImageSize(String url) {
    _removeImageSizeListener();
    final listener = _createImageSizeListener(url);
    final stream = appCachedNetworkImageProvider(url).resolve(
      const ImageConfiguration(),
    );
    _imageSizeStreamListener = listener;
    _imageSizeStream = stream;
    stream.addListener(listener);
  }

  ImageStreamListener _createImageSizeListener(String url) {
    return ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (!mounted || size == _imageSize) return;
        // 使用帧回调，避免在构建阶段调用 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || size == _imageSize || _currentUrl != url) return;
          setState(() => _imageSize = size);
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        // 尺寸获取失败时回退到附件元数据（attachment.width/height）
      },
    );
  }

  void _removeImageSizeListener() {
    final listener = _imageSizeStreamListener;
    if (listener != null) {
      _imageSizeStream?.removeListener(listener);
    }
    _imageSizeStream = null;
    _imageSizeStreamListener = null;
  }

  /// 鼠标滚轮缩放事件处理（桌面端）
  void _onPointerSignal(PointerSignalEvent evt) {
    if (evt is PointerScrollEvent) {
      final double target = imageViewerScaleForScroll(
        currentScale: _controller.scale,
        initialScale: _viewerInitialScale,
        scrollDeltaY: evt.scrollDelta.dy,
        step: _step,
        minScale: _viewerMinScale,
        maxScale: _viewerMaxScale,
      );
      _controller.scale = target;
    }
  }

  /// 放大
  void _zoomIn() {
    final double target = imageViewerScaleForScroll(
      currentScale: _controller.scale,
      initialScale: _viewerInitialScale,
      scrollDeltaY: -1,
      step: _step,
      minScale: _viewerMinScale,
      maxScale: _viewerMaxScale,
    );
    _controller.scale = target;
  }

  /// 缩小
  void _zoomOut() {
    final double target = imageViewerScaleForScroll(
      currentScale: _controller.scale,
      initialScale: _viewerInitialScale,
      scrollDeltaY: 1,
      step: _step,
      minScale: _viewerMinScale,
      maxScale: _viewerMaxScale,
    );
    _controller.scale = target;
  }

  /// 下载当前图片到相册
  Future<void> _downloadImage() async {
    if (_downloading) return;
    final messenger = ScaffoldMessenger.of(context);

    // 仅在真实移动设备上允许下载（非模拟器或桌面）
    if (!DeviceUtil.isRealMobile()) {
      messenger.showSnackBar(
        SnackBar(content: Text('image_download_mobile_only'.tr())),
      );
      return;
    }

    // 获取当前附件 URL
    final url = _currentAttachment(_galleryAttachments(watch: false)).url;
    if (url == null || url.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text('image_load_failed'.tr())));
      return;
    }

    // 申请存储权限
    final granted = await _ensureGalleryPermission();
    if (!granted) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('gallery_permission_required'.tr())),
      );
      return;
    }

    setState(() => _downloading = true);
    messenger.showSnackBar(
      SnackBar(content: Text('image_download_started'.tr())),
    );

    try {
      // 使用 Dio 下载图片二进制数据
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('empty bytes');
      }

      // 生成文件名并保存到系统相册
      final fileName = 'anoxia_image_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name: fileName,
      );

      // 判断保存结果（isSuccess 可能为 bool 或 int）
      final ok =
          result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 1);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'image_download_success'.tr() : 'image_download_failed'.tr(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('image_download_failed'.tr())),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  /// 确保拥有相册存储权限（iOS 和 Android 分别处理）
  Future<bool> _ensureGalleryPermission() async {
    return ensureGalleryWritePermission(context);
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前会话的所有图片附件列表（可能来自多个消息）
    final attachments = _galleryAttachments();
    final attachment = _currentAttachment(attachments);
    final currentIndex = _currentIndex(attachments);
    final canGoPrevious = currentIndex > 0;
    final canGoNext =
        currentIndex >= 0 && currentIndex < attachments.length - 1;

    // 如果当前附件 URL 无效，显示错误占位并允许点击关闭
    if (attachment.url == null || attachment.url!.isEmpty) {
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // 多图时显示页码
        title: attachments.length > 1
            ? Text(
                '${currentIndex + 1}/${attachments.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft02,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 放大
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedZoomInArea,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _zoomIn,
          ),
          // 缩小
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedZoomOutArea,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _zoomOut,
          ),
          // 重置缩放
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _controller.scale = _viewerInitialScale,
          ),
          // 下载（下载中禁用）
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _downloading ? null : _downloadImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 主图片展示区
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 计算缩放边界：默认原图 1:1，超大图等比缩放至不超出屏幕
                  final scales = _computeScales(attachment, constraints);
                  _rememberScaleBounds(scales);
                  return GestureDetector(
                    // 点击任意位置关闭（外层确保即使图片加载失败也能关闭）
                    onTap: () => Navigator.pop(context),
                    child: Listener(
                      // 监听鼠标滚轮事件（桌面端）
                      onPointerSignal: _onPointerSignal,
                      child: PhotoView(
                        key: ValueKey(attachment.url),
                        controller: _controller,
                        scaleStateController: _scaleStateCtrl,
                        onTapUp: (context, details, value) =>
                            Navigator.pop(context),
                        imageProvider: appCachedNetworkImageProvider(
                          attachment.url!,
                        ),
                        filterQuality: FilterQuality.high,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        initialScale: scales.initialScale,
                        minScale: scales.minScale,
                        maxScale: scales.maxScale,
                        enableRotation: false,
                        basePosition: Alignment.center,
                        // 仅在当前附件与初始一致时启用 Hero 动画
                        heroAttributes: _heroAttributesFor(attachment),
                        loadingBuilder: (context, event) => _buildLoading(
                          event,
                        ),
                        errorBuilder: (context, error, stackTrace) =>
                            _buildError(),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 多图切换按钮（左右箭头）
            if (attachments.length > 1) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildSwitchButton(
                    icon: HugeIcons.strokeRoundedArrowLeft02,
                    enabled: canGoPrevious,
                    onPressed: () => _switchTo(currentIndex - 1, attachments),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildSwitchButton(
                    icon: HugeIcons.strokeRoundedArrowRight02,
                    enabled: canGoNext,
                    onPressed: () => _switchTo(currentIndex + 1, attachments),
                  ),
                ),
              ),
            ],

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
                      attachment.name ?? 'image'.tr(),
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

  /// 获取当前会话中的所有图片附件列表
  /// [watch] 是否使用 Riverpod 的 watch 模式（监听变化）
  List<Attachment> _galleryAttachments({bool watch = true}) {
    final roomId = widget.roomId;
    if (roomId == null || roomId.isEmpty) return [widget.attachment];

    final provider = roomMessagesProvider(roomId);
    final messages = watch
        ? ref.watch(provider).value ?? const []
        : ref.read(provider).value ?? const [];
    final result = <Attachment>[];
    final seenUrls = <String>{};

    // 遍历所有消息，收集其中的图片附件（去重）
    for (final message in messages) {
      final attachments = message.payload?.mediaAttachments ?? const [];
      for (final attachment in attachments) {
        final url = attachment.url;
        if (url == null || url.isEmpty || !attachment.isImage) continue;
        if (seenUrls.add(url)) result.add(attachment);
      }
    }

    // 确保当前附件包含在列表中（防止未在消息中）
    final initialUrl = widget.attachment.url;
    if (initialUrl != null &&
        initialUrl.isNotEmpty &&
        seenUrls.add(initialUrl)) {
      result.add(widget.attachment);
    }

    return result.isEmpty ? [widget.attachment] : result;
  }

  /// 根据当前 _currentUrl 从附件列表中获取对应的 Attachment
  Attachment _currentAttachment(List<Attachment> attachments) {
    for (final attachment in attachments) {
      if (attachment.url == _currentUrl) return attachment;
    }
    return attachments.isEmpty ? widget.attachment : attachments.first;
  }

  /// 计算当前附件在列表中的索引
  int _currentIndex(List<Attachment> attachments) {
    final index = attachments.indexWhere((item) => item.url == _currentUrl);
    return index < 0 ? 0 : index;
  }

  /// 切换到指定索引的图片
  void _switchTo(int index, List<Attachment> attachments) {
    if (index < 0 || index >= attachments.length) return;
    final url = attachments[index].url;
    setState(() {
      _currentUrl = url;
      // 清空旧图尺寸，等待新图解码结果
      _imageSize = null;
    });
    if (url != null && url.isNotEmpty) _loadImageSize(url);
    // 在下一帧重置缩放为初始状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.scale = _viewerInitialScale;
    });
  }

  /// 计算图片初始缩放与缩放边界
  ///
  /// 规则：图片以原图 1:1 显示；若原图超过屏幕，则等比缩小至完整显示。
  /// 在此基础上仍支持放大/缩小查看。
  _PhotoViewScales _computeScales(
    Attachment attachment,
    BoxConstraints constraints,
  ) {
    // 视口或图片尺寸未知时，回退到默认“完整显示”策略
    final imageSize = _sizeOf(attachment);
    if (constraints.maxWidth <= 0 ||
        constraints.maxHeight <= 0 ||
        imageSize == null) {
      return _PhotoViewScales(
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2.5,
      );
    }

    final viewportW = constraints.maxWidth;
    final viewportH = constraints.maxHeight;
    final imageW = imageSize.width;
    final imageH = imageSize.height;

    // 等比缩放至完整显示的倍数（可能大于 1，此时原图本就小于屏幕）
    final double fit = math.min(viewportW / imageW, viewportH / imageH);
    // 覆盖整个屏幕所需倍数
    final double cover = math.max(viewportW / imageW, viewportH / imageH);
    // 初始：原图 1:1；超大图则等比缩小到屏幕内
    final double initial = math.min(1.0, fit);
    // 缩小下限：不超过完整显示比例的一半（小图不可再小于 1:1）
    final double min = math.min(initial, fit * 0.5);
    // 放大上限：至少可放大 2 倍
    final double max = math.max(2.0, cover * 2.5);

    return _PhotoViewScales(
      initialScale: initial,
      minScale: min,
      maxScale: max,
    );
  }

  void _rememberScaleBounds(_PhotoViewScales scales) {
    if (scales.initialScale is! num ||
        scales.minScale is! num ||
        scales.maxScale is! num) {
      return;
    }
    _viewerInitialScale = (scales.initialScale as num).toDouble();
    _viewerMinScale = (scales.minScale as num).toDouble();
    _viewerMaxScale = (scales.maxScale as num).toDouble();
  }

  /// 获取图片实际尺寸：优先解码结果，其次附件元数据
  Size? _sizeOf(Attachment attachment) {
    final size = _imageSize;
    if (size != null) return size;
    final width = attachment.width;
    final height = attachment.height;
    if (width != null && width > 0 && height != null && height > 0) {
      return Size(width.toDouble(), height.toDouble());
    }
    return null;
  }

  /// 生成 Hero 属性（仅在当前附件与初始附件一致时返回，保证过渡正确）
  PhotoViewHeroAttributes? _heroAttributesFor(Attachment attachment) {
    final initialUrl = widget.currentUrl ?? widget.attachment.url;
    if (attachment.url != initialUrl) return null;
    return PhotoViewHeroAttributes(tag: widget.heroTag);
  }

  /// 构建切换按钮（带透明度动画）
  Widget _buildSwitchButton({
    required List<List<dynamic>> icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.25,
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: HugeIcon(icon: icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// 加载中占位
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

  /// 加载失败占位
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, color: Colors.white54, size: 50),
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

/// PhotoView 缩放参数集合
class _PhotoViewScales {
  final dynamic initialScale;
  final dynamic minScale;
  final dynamic maxScale;

  const _PhotoViewScales({
    required this.initialScale,
    required this.minScale,
    required this.maxScale,
  });
}
