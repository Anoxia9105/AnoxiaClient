import 'package:cross_cache/cross_cache.dart' as cross_cache;
import 'package:flutter/material.dart';

cross_cache.CrossCache? _appImageCrossCache;

cross_cache.CrossCache get appImageCrossCache {
  return _appImageCrossCache ??= cross_cache.CrossCache();
}

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

typedef CachedImagePlaceholderBuilder =
    Widget Function(BuildContext context, String url);
typedef CachedImageErrorBuilder =
    Widget Function(BuildContext context, String url, Object error);

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

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final FilterQuality filterQuality;
  final CachedImagePlaceholderBuilder? placeholder;
  final CachedImageErrorBuilder? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
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
