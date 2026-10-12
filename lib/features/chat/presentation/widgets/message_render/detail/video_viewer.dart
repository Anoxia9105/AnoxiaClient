import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

import 'video_viewer_widgets.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

export 'video_viewer_widgets.dart'
    show VideoControlBar, VideoControlButton, formatVideoDuration;

/// 视频播放器通用状态与生命周期。
///
/// 供对话框版与全屏页面版共享，统一处理：
/// 初始化、播放/暂停、静音、进度监听、错误与自动播放。
mixin VideoPlayerControllerMixin<T extends StatefulWidget> on State<T> {
  VideoPlayerController? controller;
  bool initialized = false;
  bool initializing = false;
  bool hasError = false;
  bool isPlaying = false;
  bool isMuted = true;
  bool hasPlayed = false;
  bool _disposed = false;

  @protected
  String get videoUrl;

  @protected
  bool get autoPlayOnInit;

  void _onVideoChanged() {
    if (!mounted || controller == null) return;
    final v = controller!.value;
    if (v.hasError) {
      if (!hasError) {
        setState(() {
          hasError = true;
          isPlaying = false;
        });
      }
      return;
    }
    if (!hasPlayed && v.isPlaying) setState(() => hasPlayed = true);
    final ended = v.duration != Duration.zero && v.position >= v.duration;
    if (ended) {
      if (isPlaying) setState(() => isPlaying = false);
    } else if (v.isPlaying != isPlaying) {
      setState(() => isPlaying = v.isPlaying);
    }
    // position 的持续刷新交由 ValueListenableBuilder 单独驱动，避免整树重建。
  }

  @protected
  Future<void> initPlayer({required bool muted, bool play = true}) async {
    if (initializing || initialized || _disposed) return;
    setState(() {
      initializing = true;
      hasError = false;
    });
    final c = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await c.initialize();
      await c.setLooping(false);
      await c.setVolume(muted ? 0 : 1);
      if (!mounted || _disposed) {
        await c.dispose();
        return;
      }
      controller = c;
      initialized = true;
      isMuted = muted;
      isPlaying = false;
      c.addListener(_onVideoChanged);
      if (play) await c.play();
      if (mounted) setState(() => initializing = false);
    } catch (_) {
      c.removeListener(_onVideoChanged);
      if (identical(controller, c)) {
        controller = null;
        initialized = false;
        isPlaying = false;
      }
      if (mounted) {
        await c.dispose();
        if (!_disposed) {
          setState(() {
            initializing = false;
            hasError = true;
          });
        }
      } else {
        await c.dispose();
      }
    }
  }

  @protected
  Future<void> togglePlay() async {
    if (hasError) {
      final failed = controller;
      controller = null;
      initialized = false;
      hasPlayed = false;
      failed?.removeListener(_onVideoChanged);
      await failed?.dispose();
      if (!mounted) return;
      setState(() => hasError = false);
      await initPlayer(muted: isMuted);
      return;
    }
    if (!initialized) {
      await initPlayer(muted: true);
      return;
    }
    final c = controller!;
    if (c.value.isPlaying) {
      await c.pause();
      if (mounted) setState(() => isPlaying = false);
    } else {
      if (c.value.position >= c.value.duration) await c.seekTo(Duration.zero);
      await c.play();
      if (mounted) setState(() => isPlaying = true);
    }
  }

  @protected
  Future<void> toggleMute() async {
    if (controller == null || !initialized) return;
    final muted = !isMuted;
    await controller!.setVolume(muted ? 0 : 1);
    if (mounted) setState(() => isMuted = muted);
  }

  @override
  void dispose() {
    _disposed = true;
    controller?.removeListener(_onVideoChanged);
    controller?.dispose();
    controller = null;
    super.dispose();
  }
}

/// 视频详情 - 对话框版本（Web PC / 桌面）
class VideoViewerDialog extends ConsumerStatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final int? videoWidth;
  final int? videoHeight;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;
  const VideoViewerDialog({
    required this.videoUrl,
    this.coverUrl,
    this.videoWidth,
    this.videoHeight,
    this.fileName,
    this.fileSize,
    this.durationMs,
    super.key,
  });
  @override
  ConsumerState<VideoViewerDialog> createState() => _VideoViewerDialogState();
}

class _VideoViewerDialogState extends ConsumerState<VideoViewerDialog>
    with VideoPlayerControllerMixin {
  @override
  String get videoUrl => widget.videoUrl;

  @override
  bool get autoPlayOnInit {
    final auto = ref.read(autoPlayMediaProvider);
    return auto && !ref.read(reduceMotionProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      initPlayer(muted: true, play: autoPlayOnInit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogW = (screen.width * 0.72).clamp(320.0, 860.0).toDouble();
    final dialogH = (screen.height * 0.78).clamp(280.0, 820.0).toDouble();
    Size displaySize;
    if (widget.videoWidth != null &&
        widget.videoHeight != null &&
        widget.videoWidth! > 0 &&
        widget.videoHeight! > 0) {
      final aspect = widget.videoWidth! / widget.videoHeight!;
      var w = dialogW * 0.92;
      var h = w / aspect;
      if (h > dialogH * 0.72) {
        h = dialogH * 0.72;
        w = h * aspect;
      }
      displaySize = Size(w, h);
    } else {
      displaySize = Size(dialogW * 0.9, dialogH * 0.55);
    }

    return SizedBox(
      width: dialogW,
      height: dialogH,
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: displaySize.width,
                height: displaySize.height,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (initialized) togglePlay();
                      },
                      child: initialized && controller != null && hasPlayed
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: controller!.value.size.width,
                                height: controller!.value.size.height,
                                child: VideoPlayer(controller!),
                              ),
                            )
                          : widget.coverUrl != null &&
                                widget.coverUrl!.isNotEmpty
                          ? CachedNetworkImageView(
                              imageUrl: widget.coverUrl!,
                              width: displaySize.width,
                              height: displaySize.height,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  Container(color: Colors.grey[900]),
                              errorWidget: (_, _, _) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    if (initializing)
                      const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (hasError)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedAlert02,
                                size: 30,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'video_load_failed'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonal(
                                onPressed: togglePlay,
                                child: Text(
                                  'retry'.tr(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 顶部标题 + 关闭
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.fileName ?? 'video'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 底部控制栏（对齐到容器宽度，让进度条可用 Expanded 自适应）
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                    left: 12,
                    right: 12,
                  ),
                  child: VideoControlBar(
                    initialized: initialized,
                    isPlaying: isPlaying,
                    isMuted: isMuted,
                    hasError: hasError,
                    onTogglePlay: togglePlay,
                    onToggleMute: toggleMute,
                    controller: controller,
                    durationHint: Duration(
                      milliseconds: widget.durationMs ?? 0,
                    ),
                    initializing: initializing,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[900],
    alignment: Alignment.center,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedVideo01,
      size: 36,
      color: Colors.white54,
    ),
  );
}

/// 视频详情 - 全屏路由版本（手机/ SP），带 Hero 与主题适配
class VideoViewerPage extends ConsumerStatefulWidget {
  final String heroTag;
  final String videoUrl;
  final String? coverUrl;
  final int? videoWidth;
  final int? videoHeight;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;
  const VideoViewerPage({
    required this.heroTag,
    required this.videoUrl,
    this.coverUrl,
    this.videoWidth,
    this.videoHeight,
    this.fileName,
    this.fileSize,
    this.durationMs,
    super.key,
  });
  @override
  ConsumerState<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends ConsumerState<VideoViewerPage>
    with VideoPlayerControllerMixin {
  @override
  String get videoUrl => widget.videoUrl;

  @override
  bool get autoPlayOnInit {
    final auto = ref.read(autoPlayMediaProvider);
    return auto && !ref.read(reduceMotionProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      initPlayer(muted: true, play: autoPlayOnInit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Colors.black : Colors.grey[850];
    // 减少动效时关闭 Hero，路由本身已零时长即时呈现
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final mediaChild = initialized && controller != null && hasPlayed
        ? AspectRatio(
            aspectRatio: controller!.value.aspectRatio == 0
                ? 16 / 9
                : controller!.value.aspectRatio,
            child: VideoPlayer(controller!),
          )
        : widget.coverUrl != null && widget.coverUrl!.isNotEmpty
        ? CachedNetworkImageView(
            imageUrl: widget.coverUrl!,
            fit: BoxFit.contain,
            placeholder: (_, _) => const SizedBox.expand(),
            errorWidget: (_, _, _) => _placeholder(),
          )
        : _placeholder();
    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        title: Text(
          widget.fileName ?? 'video'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: reduceMotion
                ? mediaChild
                : Hero(
                    tag: widget.heroTag,
                    createRectTween: (b, e) =>
                        MaterialRectArcTween(begin: b, end: e),
                    flightShuttleBuilder: (ctx, anim, dir, from, to) {
                      final w = dir == HeroFlightDirection.push
                          ? to.widget
                          : from.widget;
                      return Material(color: Colors.transparent, child: w);
                    },
                    child: mediaChild,
                  ),
          ),
          if (initializing)
            const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          if (hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'video_load_failed'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: togglePlay,
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          // 底部控制栏
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: VideoControlBar(
              initialized: initialized,
              isPlaying: isPlaying,
              isMuted: isMuted,
              hasError: hasError,
              onTogglePlay: togglePlay,
              onToggleMute: toggleMute,
              controller: controller,
              durationHint: Duration(milliseconds: widget.durationMs ?? 0),
              initializing: initializing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.transparent,
    alignment: Alignment.center,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedVideo01,
      size: 48,
      color: Colors.white54,
    ),
  );
}
