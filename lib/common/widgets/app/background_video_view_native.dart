import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoView extends StatefulWidget {
  final String url;
  final bool autoplay;

  const BackgroundVideoView({
    super.key,
    required this.url,
    this.autoplay = true,
  });

  @override
  State<BackgroundVideoView> createState() => _BackgroundVideoViewState();
}

class _BackgroundVideoViewState extends State<BackgroundVideoView> {
  VideoPlayerController? _controller;
  int _initializationToken = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.autoplay != widget.autoplay) {
      _disposeController();
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final token = ++_initializationToken;
    // 缩略图只需要首帧，直接让播放器按需读取，避免为媒体库中的每个视频
    // 下载完整文件。实际播放背景时仍使用磁盘缓存。
    final cachedFile = widget.autoplay
        ? await _DesktopBackgroundVideoCache.get(widget.url)
        : null;
    if (!mounted || token != _initializationToken) return;

    final controller = cachedFile == null
        ? VideoPlayerController.networkUrl(
            Uri.parse(widget.url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
        : VideoPlayerController.file(
            cachedFile,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || !identical(_controller, controller)) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(widget.autoplay);
      await controller.setVolume(0);
      if (widget.autoplay) {
        await controller.play();
      } else {
        await controller.seekTo(Duration.zero);
      }
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
      if (mounted) setState(() {});
    }
  }

  void _disposeController() {
    _initializationToken++;
    final controller = _controller;
    _controller = null;
    if (controller != null) Future<void>.microtask(controller.dispose);
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    final size = controller.value.size;
    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

/// Keeps desktop background videos off the network playback path after the
/// first load. In-flight downloads are shared by the background and settings
/// views so the same URL is never downloaded more than once concurrently.
class _DesktopBackgroundVideoCache {
  static const int _maxVideoBytes = 120 * 1024 * 1024;
  static final Map<String, Future<File?>> _downloads = {};

  static Future<File?> get(String url) async {
    final result = await _downloads.putIfAbsent(url, () => _download(url));
    if (result == null) _downloads.remove(url);
    return result;
  }

  static Future<File?> _download(String url) async {
    File? partial;
    HttpClient? client;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') return null;
      final directory = Directory(
        '${(await getApplicationSupportDirectory()).path}'
        '${Platform.pathSeparator}background_video_cache',
      );
      await directory.create(recursive: true);
      final extension = _extension(uri.path);
      final target = File(
        '${directory.path}${Platform.pathSeparator}${_fnv1a(url)}$extension',
      );
      if (await target.exists() && await target.length() > 0) return target;

      partial = File('${target.path}.part');
      if (await partial.exists()) await partial.delete();
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.contentLength > _maxVideoBytes) return null;
      final sink = partial.openWrite();
      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        if (received > _maxVideoBytes) {
          await sink.close();
          await partial.delete();
          return null;
        }
        sink.add(chunk);
      }
      await sink.close();
      if (await partial.length() == 0) return null;
      return partial.rename(target.path);
    } catch (_) {
      if (partial != null && await partial.exists()) await partial.delete();
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.video';
    final value = path.substring(dot).toLowerCase();
    return value == '.mp4' || value == '.webm' ? value : '.video';
  }

  static String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in value.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
