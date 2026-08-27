import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 视频元数据提取结果
class VideoMetadata {
  final int? durationMs;
  final int? width;
  final int? height;

  const VideoMetadata({this.durationMs, this.width, this.height});

  bool get hasSize => width != null && height != null && width! > 0 && height! > 0;
}

/// 跨平台视频元数据提取工具
///
/// 用 [VideoPlayerController] 初始化本地文件或远程 URL，
/// 读取真实 duration / width / height。失败时返回 null 字段，
/// 调用方应回退到占位值。
class VideoMetadataUtil {
  VideoMetadataUtil._();

  /// 从本地文件路径提取元数据（原生平台）
  static Future<VideoMetadata> fromFile(String path) async {
    if (kIsWeb) return const VideoMetadata();
    final file = File(path);
    if (!file.existsSync()) return const VideoMetadata();
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      final v = controller.value;
      return VideoMetadata(
        durationMs: v.duration.inMilliseconds,
        width: v.size.width.toInt(),
        height: v.size.height.toInt(),
      );
    } catch (_) {
      return const VideoMetadata();
    } finally {
      await controller?.dispose();
    }
  }

  /// 从内存字节提取元数据（Web 端 data URI）
  static Future<VideoMetadata> fromBytes(
    Uint8List bytes, {
    String mimeType = 'video/mp4',
  }) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.dataFromBytes(bytes, mimeType: mimeType),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      final v = controller.value;
      return VideoMetadata(
        durationMs: v.duration.inMilliseconds,
        width: v.size.width.toInt(),
        height: v.size.height.toInt(),
      );
    } catch (_) {
      return const VideoMetadata();
    } finally {
      await controller?.dispose();
    }
  }

  /// 从远程 URL 提取元数据
  static Future<VideoMetadata> fromUrl(String url) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      final v = controller.value;
      return VideoMetadata(
        durationMs: v.duration.inMilliseconds,
        width: v.size.width.toInt(),
        height: v.size.height.toInt(),
      );
    } catch (_) {
      return const VideoMetadata();
    } finally {
      await controller?.dispose();
    }
  }

  /// 根据可用源自动选择提取方式
  static Future<VideoMetadata> extract({
    String? localPath,
    Uint8List? bytes,
    String? mimeType,
    String? remoteUrl,
  }) async {
    if (bytes != null && bytes.isNotEmpty) {
      return fromBytes(bytes, mimeType: mimeType ?? 'video/mp4');
    }
    if (localPath != null && localPath.isNotEmpty && !kIsWeb) {
      return fromFile(localPath);
    }
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return fromUrl(remoteUrl);
    }
    return const VideoMetadata();
  }
}
