import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 跨平台视频首帧缩略图 Widget
///
/// 用 [VideoPlayerController] 加载本地文件/远程 URL 的首帧并静态展示。
/// 关键：初始化后 `play()` → 短暂等待解码 → `pause()` + `seekTo(zero)`，
/// 才能在多数平台（含 video_player_win）渲染出真实首帧。
///
/// - 输入框 embed：本地文件/bytes 源
/// - 消息气泡：远程 URL 源（无 cover 时降级）
class VideoFirstFrameView extends StatefulWidget {
  /// 本地文件路径（原生平台）
  final String? filePath;

  /// 内存字节（Web 端 data URI）
  final Uint8List? bytes;

  /// 远程 URL
  final String? networkUrl;

  /// MIME 类型（Web data URI 用）
  final String? mimeType;

  /// 占位 Widget（首帧未加载时）
  final Widget? placeholder;

  /// 错误时是否静默降级到 placeholder
  final bool silentFallback;

  const VideoFirstFrameView({
    this.filePath,
    this.bytes,
    this.networkUrl,
    this.mimeType,
    this.placeholder,
    this.silentFallback = true,
    super.key,
  });

  @override
  State<VideoFirstFrameView> createState() => _VideoFirstFrameViewState();
}

class _VideoFirstFrameViewState extends State<VideoFirstFrameView> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _initializing = false;
  bool _retryAfterInit = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void didUpdateWidget(covariant VideoFirstFrameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.filePath != widget.filePath ||
        oldWidget.bytes != widget.bytes ||
        oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.mimeType != widget.mimeType;
    if (changed) {
      _disposeController();
      if (_initializing) {
        _retryAfterInit = true;
      } else {
        unawaited(_init());
      }
    }
  }

  Future<void> _init() async {
    if (_initializing || _initialized) return;
    _initializing = true;
    final token = ++_token;
    VideoPlayerController? pending;
    try {
      if (widget.bytes != null && widget.bytes!.isNotEmpty) {
        pending = VideoPlayerController.networkUrl(
          Uri.dataFromBytes(
            widget.bytes!,
            mimeType: widget.mimeType ?? 'video/mp4',
          ),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else if (widget.filePath != null &&
          widget.filePath!.isNotEmpty &&
          !kIsWeb) {
        final file = File(widget.filePath!);
        if (!file.existsSync()) return;
        pending = VideoPlayerController.file(
          file,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else if (widget.networkUrl != null &&
          widget.networkUrl!.isNotEmpty) {
        pending = VideoPlayerController.networkUrl(
          Uri.parse(widget.networkUrl!),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
      if (pending == null) return;
      final controller = pending;
      await controller.initialize();
      await controller.setVolume(0);
      if (!mounted || token != _token) {
        await controller.dispose();
        return;
      }
      // 提前把播放器挂载进渲染树，确保纹理在播放期间真正接收并保留帧。
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      // 播放并等待解码器真正输出至少一帧（position 前进），随后暂停停在首帧。
      final frameReady = Completer<void>();
      void onFrame() {
        final v = controller.value;
        if (v.isInitialized &&
            v.position > Duration.zero &&
            !frameReady.isCompleted) {
          frameReady.complete();
        }
      }

      controller.addListener(onFrame);
      await controller.play();
      try {
        await frameReady.future.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        // 部分格式解码器不推进 position，静默降级
      }
      controller.removeListener(onFrame);
      await controller.pause();
      // 不再 seekTo(Duration.zero)：自带即首帧，且部分后端 seek 会重置为黑帧。
    } catch (_) {
      await pending?.dispose();
      if (mounted && token == _token) {
        setState(() {
          _controller = null;
          _initialized = false;
        });
      }
    } finally {
      _initializing = false;
      if (_retryAfterInit && mounted && !_initialized) {
        _retryAfterInit = false;
        unawaited(_init());
      }
    }
  }

  void _disposeController() {
    _token++;
    final c = _controller;
    _controller = null;
    _initialized = false;
    if (c != null) unawaited(c.dispose().catchError((_) {}));
  }

  @override
  void dispose() {
    _token++;
    _initializing = true;
    final c = _controller;
    _controller = null;
    _initialized = false;
    if (c != null) unawaited(c.dispose().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_initialized && controller != null) {
      final size = controller.value.size;
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}
