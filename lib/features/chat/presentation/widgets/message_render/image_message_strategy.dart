import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import '../../../../../framework/protocol/message/Attachment.dart';
import 'base/message_render_strategy.dart';

/// 鍥剧墖娑堟伅娓叉煋绛栫暐
///
/// 澶勭悊鍥剧墖娑堟伅鐨勬樉绀猴紝鏀寔锛?
/// - 鍗曞紶鍥剧墖鏄剧ず锛堝ぇ鍥炬ā寮忥級
/// - 澶氬紶鍥剧墖鏄剧ず锛堜節瀹牸妯″紡锛?
/// - 鍥剧墖棰勮锛堢偣鍑绘斁澶э級
/// - 缂撳瓨浼樺寲鍜屽崰浣嶅浘鏄剧ず
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

    if (imageList.isEmpty) {
      return const SizedBox.shrink();
    }

    // 鑾峰彇璁惧鍍忕礌姣旓紝闃叉鍥剧墖鍦ㄩ珮鍒嗗睆妯＄硦
    final double dpr = MediaQuery.of(context).devicePixelRatio;

    // 鍗曞紶鍥剧墖鏄剧ず
    if (imageList.length == 1) {
      final attachment = imageList[0];
      final displaySize = _resolveSingleImageSize(attachment);
      final displayWidth = displaySize.width;
      final displayHeight = displaySize.height;
      final heroTag = 'image-${attachment.url}';

      return GestureDetector(
        onTap: () => ImageMessageDetailRoute(
          attachment: attachment,
          heroTag: heroTag,
          roomId: message.roomId,
          currentUrl: attachment.url,
        ).push(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImageView(
              imageUrl: attachment.url!,
              width: displayWidth,
              height: displayHeight,
              fit: BoxFit.contain,
              memCacheWidth: (displayWidth * dpr).round(),
              memCacheHeight: (displayHeight * dpr).round(),
              placeholder: (context, url) =>
                  _buildPlaceholder(displayWidth, displayHeight),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 50),
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    // 澶氬浘鏄剧ず (涔濆鏍奸鏍?
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: imageList.map((attachment) {
        const double gridSize = 100.0;
        final heroTag =
            'image-${attachment.url}-${message.messageId}'; // 澶氬浘甯︿笂娑堟伅ID闃叉Tag鍐茬獊
        return GestureDetector(
          onTap: () => ImageMessageDetailRoute(
            attachment: attachment,
            heroTag: heroTag,
            roomId: message.roomId,
            currentUrl: attachment.url,
          ).push(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImageView(
                imageUrl: attachment.url!,
                width: gridSize,
                height: gridSize,
                fit: BoxFit.cover,
                // 鍏抽敭锛氬鍥炬椂闄愬埗鍐呭瓨鍗犵敤锛屼絾淇濇寔 DPR 缂╂斁
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

  // 鎻愬彇鍗犱綅鍥剧粍浠讹紝楠ㄦ灦灞忛潤鎬佹牱寮?
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

  Size _resolveSingleImageSize(Attachment attachment) {
    const fallback = Size(200, 150);
    const maxWidth = 260.0;
    const maxHeight = 320.0;

    final rawWidth = attachment.width;
    final rawHeight = attachment.height;
    if (rawWidth == null ||
        rawHeight == null ||
        rawWidth <= 0 ||
        rawHeight <= 0) {
      return fallback;
    }

    final aspectRatio = rawWidth / rawHeight;
    var width = rawWidth.toDouble().clamp(1, maxWidth).toDouble();
    var height = width / aspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }
}
