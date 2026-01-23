import 'package:flutter/cupertino.dart';
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

    // 单张图片直接显示大图
    if (imageList.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageList[0].url!,
          width: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 50),
        ),
      );
    }

    // 多图用 GridView 或 Wrap
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            attachment.url!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 50),
          ),
        );
      }).toList(),
    );
  }
}
