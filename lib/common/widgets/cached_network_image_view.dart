import 'package:cross_cache/cross_cache.dart' as cross_cache;
import 'package:flutter/material.dart';

/// 全局图片缓存实例
///
/// 应用级别的 [CrossCache] 单例，用于缓存网络图片的磁盘和内存数据。
cross_cache.CrossCache? _appImageCrossCache;

/// 获取应用级图片缓存实例
///
/// 懒加载创建 [CrossCache]，全应用共享同一个缓存实例。
cross_cache.CrossCache get appImageCrossCache {
  return _appImageCrossCache ??= cross_cache.CrossCache();
}

/// 创建带缓存的网络图片 Provider
///
/// 替代 [NetworkImage]，通过 [CrossCache] 实现磁盘+内存双层缓存。
/// [url] 图片地址
/// [scale] 缩放比例
/// [headers] 自定义请求头
ImageProvider appCachedNetworkImageProvider(
  String url, {
  double scale = 1.0,
  Map<String, String>? headers,
}) {
  return cross_cache.CachedNetworkImage(
    url,
    appImageCrossCache,
    scale: scale,
    headers: headers,
  );
}

/// 缓存图片占位 Widget 构建器
typedef CachedImagePlaceholderBuilder =
    Widget Function(BuildContext context, String url);
/// 缓存图片错误 Widget 构建器
typedef CachedImageErrorBuilder =
    Widget Function(BuildContext context, String url, Object error);

/// 带缓存的网络图片展示组件
///
/// 封装了 [cross_cache] 的图片加载、缓存、占位和错误处理逻辑。
/// 支持内存缓存尺寸限制和磁盘缓存尺寸限制。
class CachedNetworkImageView extends StatelessWidget {
  const CachedNetworkImageView({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  /// 图片 URL
  final String imageUrl;
  /// 显示宽度
  final double? width;
  /// 显示高度
  final double? height;
  /// 图片填充方式
  final BoxFit? fit;
  /// 对齐方式
  final AlignmentGeometry alignment;
  /// 图片过滤质量
  final FilterQuality filterQuality;
  /// 加载中占位 Widget 构建器
  final CachedImagePlaceholderBuilder? placeholder;
  /// 加载失败错误 Widget 构建器
  final CachedImageErrorBuilder? errorWidget;
  /// 内存缓存宽度限制
  final int? memCacheWidth;
  /// 内存缓存高度限制
  final int? memCacheHeight;
  /// 磁盘缓存最大宽度
  final int? maxWidthDiskCache;
  /// 磁盘缓存最大高度
  final int? maxHeightDiskCache;

  @override
  Widget build(BuildContext context) {
    final provider = ResizeImage.resizeIfNeeded(
      memCacheWidth ?? maxWidthDiskCache,
      memCacheHeight ?? maxHeightDiskCache,
      appCachedNetworkImageProvider(imageUrl),
    );

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder?.call(context, imageUrl) ??
            SizedBox(width: width, height: height);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget?.call(context, imageUrl, error) ??
            const Icon(Icons.broken_image);
      },
    );
  }
}
