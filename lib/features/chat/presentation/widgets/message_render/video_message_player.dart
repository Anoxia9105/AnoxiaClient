import 'package:anoxia/common/utils/file_util.dart';
import 'package:anoxia/common/utils/media_viewer_helper.dart';
import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

import 'video_message_controls.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

class VideoMessagePlayer extends ConsumerStatefulWidget {
  final String heroTag;
  final String videoUrl;
  final String? coverUrl;
  final int? videoWidth;
  final int? videoHeight;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;

  const VideoMessagePlayer({
    super.key,
    required this.heroTag,
    required this.videoUrl,
    this.coverUrl,
    this.videoWidth,
    this.videoHeight,
    this.fileName,
    this.fileSize,
    this.durationMs,
  });

  @override
  ConsumerState<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends ConsumerState<VideoMessagePlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _initializing = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isMuted = true;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final autoPlay = ref.read(autoPlayMediaProvider);
      final reduceMotion = ref.read(reduceMotionProvider);
      if (autoPlay && !reduceMotion) {
        _initAndPlay(muted: true);
      }
    });
  }

  Future<void> _initAndPlay({required bool muted}) async {
    if (_initializing || _initialized) return;
    setState(() {
      _initializing = true;
      _hasError = false;
    });
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(muted ? 0 : 1);
      _controller = controller;
      _initialized = true;
      _isMuted = muted;
      _isPlaying = true;
      controller.addListener(_videoListener);
      await controller.play();
      if (mounted) setState(() => _initializing = false);
      _hideControlsLater();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _initializing = false;
          _hasError = true;
        });
      }
    }
  }

  void _hideControlsLater() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (value.position >= value.duration && value.duration != Duration.zero) {
      if (_isPlaying) {
        setState(() {
          _isPlaying = false;
          _showControls = true;
        });
      }
    } else if (value.isPlaying != _isPlaying) {
      setState(() => _isPlaying = value.isPlaying);
    }
  }

  Future<void> _togglePlay() async {
    if (_hasError) {
      setState(() => _hasError = false);
      await _initAndPlay(muted: _isMuted);
      return;
    }
    if (!_initialized) {
      await _initAndPlay(muted: true);
      return;
    }

    final controller = _controller!;
    if (controller.value.isPlaying) {
      await controller.pause();
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
      setState(() {
        _isPlaying = true;
        _showControls = true;
      });
      _hideControlsLater();
    }
  }

  Future<void> _toggleMute() async {
    if (!_initialized || _controller == null) return;
    final muted = !_isMuted;
    await _controller!.setVolume(muted ? 0 : 1);
    setState(() => _isMuted = muted);
  }

  void _openFullscreen() {
    // 恢复真实桌面的视频详情弹窗：统一走 media_viewer_helper 分发
    // - 真实桌面 / Web-PC -> VideoViewerDialog（对话框，独立 controller）
    // - 移动端 / Web-SP -> VideoViewerPage（Hero 路由）
    // 旧的 VideoMessageFullscreenPage 复用气泡内 controller，弹窗后易出现
    // controller 归属/生命周期错乱，已由 VideoViewerDialog/Page 替代
    if (widget.videoUrl.isEmpty) return;
    // 先暂停气泡内播放，避免弹窗后双路音频
    if (_initialized) {
      _controller?.pause();
      if (_isPlaying && mounted) setState(() => _isPlaying = false);
    }
    openVideoDetail(
      context,
      videoUrl: widget.videoUrl,
      coverUrl: widget.coverUrl,
      videoWidth: widget.videoWidth,
      videoHeight: widget.videoHeight,
      fileName: widget.fileName,
      fileSize: widget.fileSize,
      durationMs: widget.durationMs,
      heroTag: widget.heroTag,
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0
        ? '${duration.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coverUrl = widget.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final displaySize = _displaySize();
    final durationText = widget.durationMs == null || widget.durationMs! <= 0
        ? ''
        : _formatDuration(Duration(milliseconds: widget.durationMs!));
    final sizeText = widget.fileSize != null && widget.fileSize! > 0
        ? FileUtil.formatFileSize(widget.fileSize!)
        : '';
    // 与图片详情保持一致：仅在非对话框链路（手机 / Web-SP）启用 Hero，
    // 这样移动端点击展开后可丝滑越界到 VideoViewerPage
    final useHero = !shouldUseDialogForMedia(context);

    Widget buildHeroWrapper(Widget child) {
      if (!useHero) return child;
      return Hero(
        tag: widget.heroTag,
        createRectTween: (begin, end) =>
            MaterialRectArcTween(begin: begin, end: end),
        placeholderBuilder: (ctx, size, c) => c,
        flightShuttleBuilder: (ctx, anim, dir, from, to) {
          final w = dir == HeroFlightDirection.push ? to.widget : from.widget;
          return Material(color: Colors.transparent, child: w);
        },
        transitionOnUserGestures: true,
        child: child,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: displaySize.width,
        maxHeight: displaySize.height + 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              child: SizedBox(
                width: displaySize.width,
                height: displaySize.height,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_initialized && _controller != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showControls = !_showControls),
                          child: buildHeroWrapper(
                            FittedBox(
                              fit: BoxFit.contain,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          ),
                        )
                      else if (hasCover)
                        GestureDetector(
                          onTap: _togglePlay,
                          child: buildHeroWrapper(
                            CachedNetworkImageView(
                              imageUrl: coverUrl,
                              width: displaySize.width,
                              height: displaySize.height,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => ColoredBox(
                                color: colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (_, _, _) =>
                                  _placeholder(colorScheme),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _togglePlay,
                          child: buildHeroWrapper(_placeholder(colorScheme)),
                        ),
                    _bottomGradient(),
                    if (!_initializing) _playButton(),
                    if (_initializing)
                      const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      ),
                    if (_showControls) _topControls(),
                    _mediaInfo(durationText, sizeText),
                    if (_initialized && _controller != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: colorScheme.primary,
                            bufferedColor: Colors.white.withValues(alpha: 0.35),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.22,
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 8),
                        ),
                      ),
                    if (_hasError) _errorOverlay(),
                  ],
                ),
              ),
            ),
          ),
          ),
          if (widget.fileName != null &&
              widget.fileName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.fileName!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Size _displaySize() {
    if (widget.videoWidth == null ||
        widget.videoHeight == null ||
        widget.videoWidth! <= 0 ||
        widget.videoHeight! <= 0) {
      return const Size(280, 160);
    }
    final aspect = widget.videoWidth! / widget.videoHeight!;
    var width = 280.0;
    var height = width / aspect;
    if (height > 380) {
      height = 380;
      width = height * aspect;
    }
    if (height < 160) {
      height = 160;
      width = (height * aspect).clamp(0, 280);
    }
    return Size(width, height);
  }

  Widget _placeholder(ColorScheme scheme) => Container(
    color: scheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedVideo01,
          size: 36,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          'video'.tr(),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _bottomGradient() => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
        ),
      ),
    ),
  );

  Widget _playButton() => Center(
    child: Material(
      color: Colors.black.withValues(alpha: 0.36),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _togglePlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: HugeIcon(
            icon: _hasError
                ? HugeIcons.strokeRoundedRefresh
                : _isPlaying && _initialized
                ? HugeIcons.strokeRoundedPause
                : HugeIcons.strokeRoundedPlay,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  Widget _topControls() => Positioned(
    top: 8,
    right: 8,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_initialized)
          VideoMessageControlPill(
            icon: _isMuted
                ? HugeIcons.strokeRoundedVolumeMute01
                : HugeIcons.strokeRoundedVolumeHigh,
            onTap: _toggleMute,
          ),
        if (_initialized) const SizedBox(width: 8),
        VideoMessageControlPill(
          icon: HugeIcons.strokeRoundedArrowExpand01,
          onTap: _openFullscreen,
        ),
      ],
    ),
  );

  Widget _mediaInfo(String durationText, String sizeText) => Positioned(
    left: 10,
    right: 10,
    bottom: 8,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(RadiusToken.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedVideo01,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                durationText.isNotEmpty ? durationText : 'video'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sizeText.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sizeText,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        if (_initialized &&
            _controller != null &&
            _controller!.value.duration != Duration.zero)
          Text(
            '${_formatDuration(_controller!.value.position)} / '
            '${_formatDuration(_controller!.value.duration)}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
      ],
    ),
  );

  Widget _errorOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.42),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: 28,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            'video_load_failed'.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _togglePlay, child: Text('retry'.tr())),
        ],
      ),
    ),
  );
}
