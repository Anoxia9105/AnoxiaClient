import 'package:anoxia/framework/provider/router/router.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 别忘了引入
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

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
      final attachment = imageList[0];
      final heroTag = 'image-${attachment.url}';

      return GestureDetector(
        onTap: () => ImageMessageDetailRoute(
          attachment: attachment,
          heroTag: heroTag,
        ).push(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: attachment.url!,
              width: displayWidth,
              fit: BoxFit.contain,
              memCacheWidth: (displayWidth * dpr).round(),
              placeholder: (context, url) =>
                  _buildPlaceholder(displayWidth, 150),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 50),
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    // 多图显示 (九宫格风格)
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        const double gridSize = 100.0;
        final heroTag =
            'image-${attachment.url}-${message.messageId}'; // 多图带上消息ID防止Tag冲突
        return GestureDetector(
          onTap: () => ImageMessageDetailRoute(
            attachment: attachment,
            heroTag: heroTag,
          ).push(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Hero(
              tag: heroTag,
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
            ),
          ),
        );
      }).toList(),
    );
  }

  // 提取占位图组件，骨架屏静态样式
  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
        ),
      ),
    );
  }
}
