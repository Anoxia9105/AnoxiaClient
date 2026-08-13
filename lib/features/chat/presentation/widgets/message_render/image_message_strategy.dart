import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';
import 'image_render_metrics.dart';

/// Renders image messages using the dimensions carried by the message protocol.
class ImageMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final imageList =
        message.payload?.mediaAttachments
            .where((attachment) => attachment.isImage)
            .toList() ??
        const [];
    if (imageList.isEmpty) return const SizedBox.shrink();

    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (imageList.length == 1) {
      final attachment = imageList.single;
      final displaySize = resolveImageMessageDisplaySize(attachment);
      final heroTag = 'image-${attachment.url}';
      return GestureDetector(
        onTap: () => context.push(
          ImageMessageDetailRoute(
            heroTag: heroTag,
            roomId: message.roomId,
            currentUrl: attachment.url,
          ).location,
          extra: attachment,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImageView(
                imageUrl: attachment.url!,
                width: displaySize.width,
                height: displaySize.height,
                fit: BoxFit.contain,
                memCacheWidth: (displaySize.width * dpr).round(),
                memCacheHeight: (displaySize.height * dpr).round(),
                placeholder: (_, _) => _buildPlaceholder(displaySize),
                errorWidget: (_, _, _) => const HugeIcon(
                  icon: HugeIcons.strokeRoundedImageNotFound01,
                  size: 50,
                ),
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        const gridSize = 100.0;
        final heroTag = 'image-${attachment.url}-${message.messageId}';
        return GestureDetector(
          onTap: () => context.push(
            ImageMessageDetailRoute(
              heroTag: heroTag,
              roomId: message.roomId,
              currentUrl: attachment.url,
            ).location,
            extra: attachment,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Hero(
                tag: heroTag,
                child: CachedNetworkImageView(
                  imageUrl: attachment.url!,
                  width: gridSize,
                  height: gridSize,
                  fit: BoxFit.cover,
                  memCacheWidth: (gridSize * dpr).round(),
                  memCacheHeight: (gridSize * dpr).round(),
                  placeholder: (_, _) =>
                      _buildPlaceholder(const Size.square(gridSize)),
                  errorWidget: (_, _, _) => const HugeIcon(
                    icon: HugeIcons.strokeRoundedImageNotFound01,
                    size: 30,
                  ),
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholder(Size size) {
    return Container(
      width: size.width,
      height: size.height,
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
