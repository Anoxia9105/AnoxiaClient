import 'package:anoxia/common/utils/file_util.dart';
import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

import 'base/message_render_strategy.dart';

/// 视频消息渲染策略
///
/// 最佳实践：
/// - 封面优先：使用 `payload.cover` 或 `video.thumbnailUrl`，无封面时显示占位
/// - 懒加载：仅在用户点击或自动播放开启时初始化 [VideoPlayerController]
/// - 自动播放：受 `autoPlayMediaProvider` 与 `reduceMotionProvider` 控制，
///   浏览器自动播放策略要求静音，自动播放时默认静音
/// - 性能：单例控制器、按需初始化、未可见时暂停（页面销毁即 dispose）
/// - 交互：点击封面播放/暂停、底部进度、时长/大小信息、静音切换、全屏入口
/// - 容错：网络失败显示重试，时长与尺寸缺失时降级显示
class VideoMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final video = message.payload?.video;
    if (video == null || video.url == null || video.url!.isEmpty) {
      return const SizedBox.shrink();
    }
    final cover = message.payload?.cover;
    final durationMs = message.payload?.audioDuration;
    return _VideoMessageWidget(
      videoUrl: video.url!,
      coverUrl: cover?.url ?? video.thumbnailUrl,
      videoWidth: video.width,
      videoHeight: video.height,
      fileName: video.name,
      fileSize: video.size,
      durationMs: durationMs,
    );
  }
}

class _VideoMessageWidget extends ConsumerStatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final int? videoWidth;
  final int? videoHeight;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;

  const _VideoMessageWidget({
    required this.videoUrl,
    this.coverUrl,
    this.videoWidth,
    this.videoHeight,
    this.fileName,
    this.fileSize,
    this.durationMs,
  });

  @override
  ConsumerState<_VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends ConsumerState<_VideoMessageWidget> {
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
    // 延迟一帧后根据设置决定是否自动播放，避免构建期间 read 冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final autoPlay = ref.read(autoPlayMediaProvider);
      final reduceMotion = ref.read(reduceMotionProvider);
      if (autoPlay && !reduceMotion && !kIsWeb) {
        // Web 端自动播放受浏览器策略限制更严格，默认不自动播，保留点击行为
        _initAndPlay(muted: true);
      } else if (autoPlay && !reduceMotion && kIsWeb) {
        // Web 端若开启自动播放，仍尝试静音自动播（符合策略）
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
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
      // 3 秒后自动隐藏控制层
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
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

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    // 播放结束时显示控制层
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
    final c = _controller!;
    if (c.value.isPlaying) {
      await c.pause();
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
    } else {
      // 播完后重播
      if (c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
      setState(() {
        _isPlaying = true;
        _showControls = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
    }
  }

  Future<void> _toggleMute() async {
    if (!_initialized || _controller == null) return;
    final newMuted = !_isMuted;
    await _controller!.setVolume(newMuted ? 0 : 1);
    setState(() => _isMuted = newMuted);
  }

  void _openFullscreen() {
    if (!_initialized || _controller == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoFullscreenPage(
          controller: _controller!,
          title: widget.fileName ?? 'video',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _formatDurationMs(int? ms) {
    if (ms == null || ms <= 0) return '';
    final d = Duration(milliseconds: ms);
    return _formatDuration(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coverUrl = widget.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    // 计算显示尺寸：优先使用视频原始宽高，限制最大 320x 240，最小 180x 120
    Size displaySize;
    if (widget.videoWidth != null && widget.videoHeight != null && widget.videoWidth! > 0 && widget.videoHeight! > 0) {
      final aspect = widget.videoWidth! / widget.videoHeight!;
      const maxW = 280.0;
      const maxH = 380.0;
      var w = maxW;
      var h = w / aspect;
      if (h > maxH) {
        h = maxH;
        w = h * aspect;
      }
      if (h < 160) {
        h = 160;
        w = h * aspect;
        if (w > maxW) w = maxW;
      }
      displaySize = Size(w, h);
    } else {
      displaySize = const Size(280, 160);
    }

    final durationText = _formatDurationMs(widget.durationMs);
    final sizeText = widget.fileSize != null && widget.fileSize! > 0 ? FileUtil.formatFileSize(widget.fileSize!) : '';

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: displaySize.width, maxHeight: displaySize.height + 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: displaySize.width,
              height: displaySize.height,
              color: colorScheme.surfaceContainerHighest,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 底层：视频或封面
                  if (_initialized && _controller != null)
                    GestureDetector(
                      onTap: () => setState(() => _showControls = !_showControls),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    )
                  else if (hasCover)
                    GestureDetector(
                      onTap: _togglePlay,
                      child: CachedNetworkImageView(
                        imageUrl: coverUrl,
                        width: displaySize.width,
                        height: displaySize.height,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: colorScheme.surfaceContainerHighest),
                        errorWidget: (_, _, _) => _buildPlaceholder(colorScheme),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _togglePlay,
                      child: _buildPlaceholder(colorScheme),
                    ),

                  // 渐变遮罩（底部信息可读性）
                  Positioned(
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
                  ),

                  // 居中播放按钮
                  if (!_initializing)
                    Center(
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
                                  : (_isPlaying && _initialized
                                      ? HugeIcons.strokeRoundedPause
                                      : HugeIcons.strokeRoundedPlay),
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 加载中
                  if (_initializing)
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                      ),
                    ),

                  // 顶部工具栏（静音 / 全屏）
                  if (_initialized && _showControls)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ControlPill(
                            icon: _isMuted ? HugeIcons.strokeRoundedVolumeMute01 : HugeIcons.strokeRoundedVolumeHigh,
                            onTap: _toggleMute,
                          ),
                          const SizedBox(width: 8),
                          _ControlPill(
                            icon: HugeIcons.strokeRoundedArrowExpand01,
                            onTap: _openFullscreen,
                          ),
                        ],
                      ),
                    ),

                  // 底部信息栏
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedVideo01, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                durationText.isNotEmpty ? durationText : 'video'.tr(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (sizeText.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(sizeText, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_initialized && _controller != null && _controller!.value.duration != Duration.zero)
                          Text(
                            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                          ),
                      ],
                    ),
                  ),

                  // 进度条
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
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                        padding: const EdgeInsets.only(top: 8, bottom: 0),
                      ),
                    ),

                  // 错误提示覆盖
                  if (_hasError)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.42),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 28, color: Colors.white),
                            const SizedBox(height: 8),
                            Text('video_load_failed'.tr(), style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: () => _togglePlay(),
                              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: Text('retry'.tr() , style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.fileName != null && widget.fileName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.fileName!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedVideo01, size: 36, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text('video'.tr(), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ControlPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  const _ControlPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: HugeIcon(icon: icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _VideoFullscreenPage extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;
  const _VideoFullscreenPage({required this.controller, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.white24,
        onPressed: () {
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, value, _) => HugeIcon(
            icon: value.isPlaying ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
