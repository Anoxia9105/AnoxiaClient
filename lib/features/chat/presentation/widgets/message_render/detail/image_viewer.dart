import 'dart:io';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

/// 鍥剧墖鏌ョ湅鍣ㄧ粍浠?
///
/// 鎻愪緵鍏ㄥ睆鍥剧墖棰勮鍔熻兘锛屾敮鎸侊細
/// - 鎵嬪娍缂╂斁锛堝弻鎸囨崗鍚堛€侀紶鏍囨粴杞級
/// - 鏀惧ぇ/缂╁皬鎸夐挳
/// - 閲嶇疆缂╂斁鎸夐挳
/// - 鍥剧墖涓嬭浇鍔熻兘
/// - Hero 鍔ㄧ敾杩囨浮
/// - 鍔犺浇鐘舵€佸拰閿欒澶勭悊
///
/// [attachment] 鍥剧墖闄勪欢淇℃伅
/// [heroTag] Hero 鍔ㄧ敾鏍囩
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
  late final PhotoViewController _controller;
  late final PhotoViewScaleStateController _scaleStateCtrl;
  bool _downloading = false;
  late String? _currentUrl;

  static const double _step = 0.2;
  static const double _minScaleFactor = 0.5;
  static const double _maxScaleFactor = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _scaleStateCtrl = PhotoViewScaleStateController();
    _currentUrl = widget.currentUrl ?? widget.attachment.url;
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

  Future<void> _downloadImage() async {
    if (_downloading) return;

    if (!DeviceUtil.isRealMobile()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('image_download_mobile_only'.tr())),
      );
      return;
    }

    final url = _currentAttachment(_galleryAttachments(watch: false)).url;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('image_load_failed'.tr())));
      return;
    }

    final granted = await _ensureGalleryPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('gallery_permission_required'.tr())),
      );
      return;
    }

    setState(() => _downloading = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('image_download_started'.tr())));

    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('empty bytes');
      }

      final fileName = 'anoxia_image_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name: fileName,
      );

      final ok =
          result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'image_download_success'.tr() : 'image_download_failed'.tr(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('image_download_failed'.tr())));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final attachments = _galleryAttachments();
    final attachment = _currentAttachment(attachments);
    final currentIndex = _currentIndex(attachments);
    final canGoPrevious = currentIndex > 0;
    final canGoNext =
        currentIndex >= 0 && currentIndex < attachments.length - 1;

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
            onPressed: _downloading ? null : _downloadImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 涓讳綋鍥剧墖灞曠ず鍖?
            Positioned.fill(
              child: GestureDetector(
                // 鍏滃簳鍏抽棴锛歟rrorBuilder 浼氭浛鎹㈡暣涓?PhotoView锛屽鑷?onTapUp 澶辨晥
                // 澶栧眰濂?GestureDetector 纭繚浠讳綍鎯呭喌涓嬬偣鍑婚兘鑳藉叧闂?
                onTap: () => Navigator.pop(context),
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: PhotoView(
                    key: ValueKey(attachment.url),
                    controller: _controller,
                    scaleStateController: _scaleStateCtrl,
                    onTapUp: (context, details, value) =>
                        Navigator.pop(context),
                    imageProvider: CachedNetworkImageProvider(attachment.url!),
                    filterQuality: FilterQuality.high,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.5,
                    enableRotation: false,
                    basePosition: Alignment.center,
                    heroAttributes: _heroAttributesFor(attachment),
                    loadingBuilder: (context, event) => _buildLoading(event),
                    errorBuilder: (context, error, stackTrace) => _buildError(),
                  ),
                ),
              ),
            ),
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

            // 搴曢儴鏂囦欢鍚嶆彁绀猴紙绌块€忕偣鍑伙紝涓嶆嫤鎴叧闂墜鍔匡級
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

  List<Attachment> _galleryAttachments({bool watch = true}) {
    final roomId = widget.roomId;
    if (roomId == null || roomId.isEmpty) return [widget.attachment];

    final selector = chatMessagesProvider.select(
      (state) => state[roomId] ?? const [],
    );
    final messages = watch ? ref.watch(selector) : ref.read(selector);
    final result = <Attachment>[];
    final seenUrls = <String>{};

    for (final message in messages) {
      final attachments = message.payload?.mediaAttachments ?? const [];
      for (final attachment in attachments) {
        final url = attachment.url;
        if (url == null || url.isEmpty || !attachment.isImage) continue;
        if (seenUrls.add(url)) result.add(attachment);
      }
    }

    final initialUrl = widget.attachment.url;
    if (initialUrl != null &&
        initialUrl.isNotEmpty &&
        seenUrls.add(initialUrl)) {
      result.add(widget.attachment);
    }

    return result.isEmpty ? [widget.attachment] : result;
  }

  Attachment _currentAttachment(List<Attachment> attachments) {
    for (final attachment in attachments) {
      if (attachment.url == _currentUrl) return attachment;
    }
    return attachments.isEmpty ? widget.attachment : attachments.first;
  }

  int _currentIndex(List<Attachment> attachments) {
    final index = attachments.indexWhere((item) => item.url == _currentUrl);
    return index < 0 ? 0 : index;
  }

  void _switchTo(int index, List<Attachment> attachments) {
    if (index < 0 || index >= attachments.length) return;
    setState(() => _currentUrl = attachments[index].url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.scale = _controller.initial.scale;
    });
  }

  PhotoViewHeroAttributes? _heroAttributesFor(Attachment attachment) {
    final initialUrl = widget.currentUrl ?? widget.attachment.url;
    if (attachment.url != initialUrl) return null;
    return PhotoViewHeroAttributes(tag: widget.heroTag);
  }

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
