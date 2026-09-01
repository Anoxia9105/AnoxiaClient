import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// PhotoView 缩放参数集合
class PhotoViewScales {
  final dynamic initialScale;
  final dynamic minScale;
  final dynamic maxScale;

  const PhotoViewScales({
    required this.initialScale,
    required this.minScale,
    required this.maxScale,
  });
}

/// 图片查看器切换按钮（带透明度动画）
///
/// 用于多图浏览时左右切换
class ImageViewerSwitchButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool enabled;
  final VoidCallback onPressed;

  const ImageViewerSwitchButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.25,
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: HugeIcon(icon: icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// 图片查看器加载中占位
class ImageViewerLoading extends StatelessWidget {
  final ImageChunkEvent? event;

  const ImageViewerLoading({
    this.event,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: e == null
              ? null
              : e.cumulativeBytesLoaded / (e.expectedTotalBytes ?? 1),
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 图片查看器加载失败占位
class ImageViewerError extends StatelessWidget {
  const ImageViewerError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            color: Colors.white54,
            size: 50,
          ),
          const SizedBox(height: 8),
          Text(
            'image_failed_to_load'.tr(),
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Text(
            'tap_to_close'.tr(),
            style: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 图片查看器底部文件名提示
class ImageViewerCaption extends StatelessWidget {
  final String text;

  const ImageViewerCaption({
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
