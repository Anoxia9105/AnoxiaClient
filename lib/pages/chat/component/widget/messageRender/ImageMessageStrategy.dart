import 'package:cached_network_image/cached_network_image.dart'; // 别忘了引入
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class ImageMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final imageList = message.attachments;

    if (imageList.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取设备像素比，防止图片在高分屏模糊
    final double dpr = MediaQuery.of(context).devicePixelRatio;

    // 单张图片显示
    if (imageList.length == 1) {
      const double displayWidth = 200.0;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageList[0].url!,
          width: displayWidth,
          fit: BoxFit.contain,
          // 关键：设置内存缓存大小为 容器宽度 * DPR
          memCacheWidth: (displayWidth * dpr).round(),
          placeholder: (context, url) => _buildPlaceholder(displayWidth, 150),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 50),
          filterQuality: FilterQuality.medium, // 权衡性能与清晰度
        ),
      );
    }

    // 多图显示 (九宫格风格)
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        const double gridSize = 100.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: attachment.url!,
            width: gridSize,
            height: gridSize,
            fit: BoxFit.cover,
            // 关键：多图时限制内存占用，但保持 DPR 缩放
            memCacheWidth: (gridSize * dpr).round(),
            memCacheHeight: (gridSize * dpr).round(),
            placeholder: (context, url) =>
                _buildPlaceholder(gridSize, gridSize),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, size: 30),
            filterQuality: FilterQuality.medium,
          ),
        );
      }).toList(),
    );
  }

  // 提取占位图组件，保持界面整洁
  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
