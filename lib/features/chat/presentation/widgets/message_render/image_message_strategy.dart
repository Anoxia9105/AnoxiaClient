import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/common/utils/media_url_util.dart';
import 'package:anoxia/common/utils/media_viewer_helper.dart';
import 'package:anoxia/common/widgets/attachment_image_view.dart';
import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../framework/domain/chat_message.dart';
import '../../../../../framework/protocol/message/attachment.dart';
import 'attachment_upload_overlay.dart';
import 'base/message_render_strategy.dart';
import 'image_render_metrics.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// Renders image messages using the dimensions carried by the message protocol.
///
/// - 支持 GIF 的受控播放：`autoPlayMediaProvider` 关闭时显示首帧 + 播放按钮，点击播放一次
/// - Hero 优化：唯一 tag + MaterialRectArcTween + flightShuttleBuilder + placeholderBuilder
/// - 响应式详情：Web/桌面 使用对话框，Web/SP 使用 Hero 路由
class ImageMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final imageList =
        message.payload?.mediaAttachments
            .where((attachment) => attachment.isImage)
            .toList() ??
        const [];
    if (imageList.isEmpty) return const SizedBox.shrink();

    if (imageList.length == 1) {
      final attachment = imageList.single;
      final heroTag = buildImageHeroTag(
        message.messageId ?? message.clientMsgId,
        attachment,
      );
      return _SingleImageItem(
        attachment: attachment,
        messageId: message.messageId ?? message.clientMsgId,
        roomId: message.roomId,
        heroTag: heroTag,
        isGrid: false,
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        final heroTag = buildImageHeroTag(
          message.messageId ?? message.clientMsgId,
          attachment,
        );
        return _SingleImageItem(
          attachment: attachment,
          messageId: message.messageId ?? message.clientMsgId,
          roomId: message.roomId,
          heroTag: heroTag,
          isGrid: true,
        );
      }).toList(),
    );
  }
}

class _SingleImageItem extends ConsumerStatefulWidget {
  final Attachment attachment;
  final String? messageId;
  final String? roomId;
  final String heroTag;
  final bool isGrid;
  const _SingleImageItem({
    required this.attachment,
    required this.messageId,
    required this.roomId,
    required this.heroTag,
    required this.isGrid,
  });
  @override
  ConsumerState<_SingleImageItem> createState() => _SingleImageItemState();
}

class _SingleImageItemState extends ConsumerState<_SingleImageItem> {
  ui.Image? _firstFrame;
  ImageStream? _frameStream;
  ImageStreamListener? _frameListener;
  ImageStream? _dimensionStream;
  ImageStreamListener? _dimensionListener;
  Size? _intrinsicSize;
  bool _isPlayingOnce = false;
  Timer? _stopTimer;
  bool _loadingFirstFrame = false;

  bool get _isGif => widget.attachment.isGif;

  /// 附件还指向本地文件：上传尚未完成，不能走网络加载，也不能开大图详情
  bool get _isPendingUpload => isPendingLocalMediaUrl(widget.attachment.url);

  /// Web 端本地待上传图片只有内存字节可读
  Uint8List? get _localBytes => ref
      .read(chatImageUploadControllerProvider.notifier)
      .bytesOf(widget.attachment.id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadFirstFrame();
      _maybeResolveIntrinsicSize();
    });
  }

  @override
  void didUpdateWidget(covariant _SingleImageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.url != widget.attachment.url) {
      _disposeFirstFrame();
      _removeDimensionListener();
      _intrinsicSize = null;
      _isPlayingOnce = false;
      _stopTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeLoadFirstFrame();
        _maybeResolveIntrinsicSize();
      });
    }
  }

  void _maybeResolveIntrinsicSize() {
    if ((widget.attachment.width ?? 0) > 0 &&
        (widget.attachment.height ?? 0) > 0) {
      return;
    }
    if (_intrinsicSize != null || _dimensionListener != null) return;
    final url = widget.attachment.url;
    if (url == null || url.isEmpty) return;
    // 本地待上传图片走 FileImage / MemoryImage，远程走缓存网络图，
    // 两者都能解析出内在尺寸，避免气泡先按默认比例渲染再跳变。
    final provider = AttachmentImageView.resolveImageProvider(
      url,
      bytes: _localBytes,
    );
    if (provider == null) return;
    final stream = provider.resolve(const ImageConfiguration());
    _dimensionStream = stream;
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!mounted) return;
      final decoded = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      _removeDimensionListener();
      if (decoded.width <= 0 || decoded.height <= 0) return;
      setState(() => _intrinsicSize = decoded);
    }, onError: (_, _) => _removeDimensionListener());
    _dimensionListener = listener;
    stream.addListener(listener);
  }

  void _removeDimensionListener() {
    final listener = _dimensionListener;
    if (listener != null) {
      _dimensionStream?.removeListener(listener);
    }
    _dimensionStream = null;
    _dimensionListener = null;
  }

  void _maybeLoadFirstFrame() {
    // GIF 静态首帧必须走网络缓存，本地待上传阶段直接交给本地图片渲染。
    if (!_isGif || _isPendingUpload) return;
    final autoPlay = ref.read(autoPlayMediaProvider);
    final reduce = ref.read(reduceMotionProvider);
    final shouldShowStatic = !autoPlay || reduce;
    if (!shouldShowStatic) return;
    if (_firstFrame != null || _loadingFirstFrame) return;
    _loadFirstFrame();
  }

  Future<void> _loadFirstFrame() async {
    final url = widget.attachment.url;
    if (url == null || url.isEmpty) return;
    setState(() => _loadingFirstFrame = true);
    final provider = appCachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    _frameStream = stream;
    final listener = ImageStreamListener(
      (ImageInfo info, bool sync) {
        if (!mounted) return;
        if (_firstFrame != null) return;
        // 捕获首帧后立即移除监听，避免后续帧更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _firstFrame = info.image.clone();
            _loadingFirstFrame = false;
          });
        });
        _removeListener();
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() => _loadingFirstFrame = false);
        _removeListener();
      },
    );
    _frameListener = listener;
    stream.addListener(listener);
    // 降级：如果 2s 内未获得首帧，取消 loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _loadingFirstFrame && _firstFrame == null) {
        setState(() => _loadingFirstFrame = false);
      }
    });
  }

  void _removeListener() {
    final l = _frameListener;
    if (l != null) _frameStream?.removeListener(l);
    _frameStream = null;
    _frameListener = null;
  }

  void _disposeFirstFrame() {
    _removeListener();
    _firstFrame?.dispose();
    _firstFrame = null;
    _stopTimer?.cancel();
    _stopTimer = null;
  }

  @override
  void dispose() {
    _disposeFirstFrame();
    _removeDimensionListener();
    super.dispose();
  }

  Future<int> _computeGifLoopMs(String url) async {
    try {
      Uint8List bytes;
      try {
        bytes = await appImageCrossCache.get(url);
      } catch (_) {
        final resp = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = resp.data;
        if (data == null || data.isEmpty) return 3000;
        bytes = Uint8List.fromList(data);
      }
      final codec = await ui.instantiateImageCodec(bytes);
      int total = 0;
      for (int i = 0; i < codec.frameCount; i++) {
        final info = await codec.getNextFrame();
        total += info.duration.inMilliseconds;
        info.image.dispose();
      }
      codec.dispose();
      if (total <= 0) return 3000;
      // 一次循环时长，夹在 800ms ~ 8000ms 之间避免极端
      return total.clamp(800, 8000);
    } catch (_) {
      return 3000;
    }
  }

  Future<void> _playOnce() async {
    if (_isPlayingOnce) return;
    setState(() => _isPlayingOnce = true);
    final url = widget.attachment.url!;
    final loopMs = await _computeGifLoopMs(url);
    _stopTimer?.cancel();
    _stopTimer = Timer(Duration(milliseconds: loopMs), () {
      if (!mounted) return;
      setState(() => _isPlayingOnce = false);
    });
  }

  void _openDetail() {
    openImageDetail(
      context,
      attachment: widget.attachment,
      heroTag: widget.heroTag,
      roomId: widget.roomId,
      currentUrl: widget.attachment.url,
    );
  }

  Size _resolveDisplaySize(BoxConstraints? constraints) {
    if (widget.isGrid) return const Size.square(100);
    final maxAllowed = constraints?.maxWidth.isFinite == true
        ? constraints!.maxWidth
        : imageMessageMaxWidth;
    // Bubble padding (12*2) + avatar gap 已由 Flexible 约束，额外预留 24
    final effectiveMaxWidth = maxAllowed < imageMessageMaxWidth
        ? maxAllowed
        : imageMessageMaxWidth;
    return resolveImageMessageDisplaySize(
      widget.attachment,
      maxWidth: effectiveMaxWidth,
      maxHeight: imageMessageMaxHeight,
      intrinsicWidth: _intrinsicSize?.width,
      intrinsicHeight: _intrinsicSize?.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final autoPlay = ref.watch(autoPlayMediaProvider);
    final reduce = ref.watch(reduceMotionProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final isGif = _isGif;
    final isPendingUpload = _isPendingUpload;
    final shouldAutoPlay = autoPlay && !reduce;
    final showStaticGif =
        isGif && !shouldAutoPlay && !_isPlayingOnce && !isPendingUpload;

    // 监听设置变化：从关闭 -> 开启 时，停止单次播放状态并尝试释放首帧
    ref.listen(autoPlayMediaProvider, (prev, next) {
      if (next && !reduce) {
        _stopTimer?.cancel();
        if (_isPlayingOnce) setState(() => _isPlayingOnce = false);
      } else {
        _maybeLoadFirstFrame();
      }
    });
    ref.listen(reduceMotionProvider, (prev, next) {
      if (next) {
        _maybeLoadFirstFrame();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final displaySize = _resolveDisplaySize(constraints);

        Widget imageChild;
        if (showStaticGif) {
          // 静态首帧
          if (_firstFrame != null) {
            imageChild = RawImage(
              image: _firstFrame,
              width: displaySize.width,
              height: displaySize.height,
              fit: widget.isGrid ? BoxFit.cover : BoxFit.contain,
              filterQuality: FilterQuality.medium,
            );
          } else {
            imageChild = _buildPlaceholder(displaySize);
          }
        } else {
          // 正常动画或普通图片：等比缩放，BoxFit.contain 保证不拉伸
          // 本地待上传（url 是本地路径/合成地址）时自动走文件或内存字节。
          imageChild = AttachmentImageView(
            url: widget.attachment.url,
            bytes: _localBytes,
            width: displaySize.width,
            height: displaySize.height,
            fit: widget.isGrid ? BoxFit.cover : BoxFit.contain,
            memCacheWidth: (displaySize.width * dpr).round().clamp(0, 2048),
            memCacheHeight: (displaySize.height * dpr).round().clamp(0, 2048),
            placeholder: (_, _) => _buildPlaceholder(displaySize),
            errorWidget: (_, _, _) => const HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound01,
              size: 30,
            ),
          );
        }

        final borderRadius = BorderRadius.circular(widget.isGrid ? 4 : 8);
        // Hero 仅在非静态 GIF 时启用，避免首帧 RawImage 与 PhotoView hero 不一致；
        // 本地待上传阶段也不启用（详情页按网络地址加载，此时还没有地址）。
        final useHero = !showStaticGif && !isPendingUpload;
        Widget heroWrapped = RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: borderRadius,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: useHero
                  ? Hero(
                      tag: widget.heroTag,
                      createRectTween: (begin, end) =>
                          MaterialRectArcTween(begin: begin, end: end),
                      placeholderBuilder: (ctx, size, child) => child,
                      flightShuttleBuilder: (ctx, anim, dir, from, to) {
                        final w = dir == HeroFlightDirection.push
                            ? to.widget
                            : from.widget;
                        return Material(color: Colors.transparent, child: w);
                      },
                      transitionOnUserGestures: true,
                      child: imageChild,
                    )
                  : imageChild,
            ),
          ),
        );

        // 点击整图打开详情；GIF 静态时中间播放按钮仅触发单次播放
        // 上传中的图片不响应点击（详情页按服务器地址加载，此时还没有地址）
        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: isPendingUpload ? null : _openDetail,
              child: heroWrapped,
            ),
            if (showStaticGif)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _openDetail,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
            if (showStaticGif)
              Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _playOnce,
                  child: Padding(
                    padding: EdgeInsets.all(widget.isGrid ? 6 : 10),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      size: widget.isGrid ? 18 : 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (isGif && !showStaticGif && !shouldAutoPlay && _isPlayingOnce)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(RadiusToken.pill),
                  ),
                  child: const Text(
                    'gif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            AttachmentUploadOverlay(attachmentId: widget.attachment.id),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
        ),
      ),
    );
  }
}
