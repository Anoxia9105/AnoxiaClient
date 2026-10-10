import 'dart:io';

import 'package:anoxia/common/utils/media_url_util.dart';
import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 图片附件的统一渲染组件
///
/// 同时覆盖三种 URL 形态（聊天气泡与编辑器图片嵌入共用）：
/// - `http(s)://`：服务器资源，走 [CachedNetworkImageView]（内存 + 磁盘缓存）；
/// - 本地绝对路径（乐观发送期间尚未上传完成）：非 Web 走 `Image.file`；
/// - 本地待上传图片（含 Web/Wasm）：优先用内存 `bytes`，用 `Image.memory`。
///
/// Web（含 Wasm）端 `dart:io` 的 `File` 不可用（会抛
/// `Unsupported operation: Platform._operatingSystem`），因此本地路径分支
/// 必须用 [kIsWeb] 守卫；且 `blob:` / `local-pending://` 合成地址永远不是
/// 磁盘路径，不可传给 `File`。
class AttachmentImageView extends StatelessWidget {
  const AttachmentImageView({
    required this.url,
    super.key,
    this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  /// 附件地址：服务器 URL 或本地文件路径
  final String? url;

  /// 本地字节（Web/Wasm 唯一来源；原生端有 bytes 时也优先用它，避免占位地址误进 File）
  final Uint8List? bytes;

  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// 网络图加载中占位（本地图片不触发）
  final Widget Function(BuildContext context, String url)? placeholder;

  /// 加载失败占位
  final Widget Function(BuildContext context, String url, Object error)?
  errorWidget;

  /// URL 是否为远程资源
  static bool isRemoteUrl(String? url) => isRemoteMediaUrl(url);

  /// 解析出对应的 [ImageProvider]（本地/远程统一入口）
  ///
  /// 供需要预解析内在尺寸（intrinsic size）的调用方复用，避免各处重复判断
  /// URL 形态后各写一份分支。无法解析时返回 null。
  static ImageProvider? resolveImageProvider(String? url, {Uint8List? bytes}) {
    if (isRemoteMediaUrl(url)) {
      return appCachedNetworkImageProvider(url!);
    }
    // 有内存字节时全平台优先用它：Web/Wasm 唯一可用来源，原生端也能避免
    // `local-pending://` / `blob:` 占位地址被误传给 File。
    if (bytes != null && bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
    if (kIsWeb) {
      return null;
    }
    final path = localMediaFilePath(url);
    return path == null ? null : FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final remote = isRemoteMediaUrl(url);
    final localBytes = bytes;

    if (remote) {
      return CachedNetworkImageView(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    if (kIsWeb) {
      if (localBytes != null && localBytes.isNotEmpty) {
        return Image.memory(
          localBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildError(context, error),
        );
      }
      return _buildError(context, StateError('web 端本地图片缺少内存字节，无法预览'));
    }

    // 原生端同样优先用内存字节（粘贴/刚选完尚未落盘、或 url 为合成占位时）。
    if (localBytes != null && localBytes.isNotEmpty) {
      return Image.memory(
        localBytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildError(context, error),
      );
    }

    final path = localMediaFilePath(url);
    if (path == null) {
      return _buildError(context, StateError('图片地址为空'));
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildError(context, error),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return errorWidget?.call(context, url ?? '', error) ??
        const SizedBox.shrink();
  }
}
