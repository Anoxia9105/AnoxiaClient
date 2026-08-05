/// 表情消息渲染策略
///
/// 处理两种表情消息：
/// - Unicode emoji（无图片附件）：沿用超大字体渲染
/// - 自定义表情包（payload.asset 携带图片附件）：以图片渲染，无气泡背景，
///   尺寸按附件宽高等比缩放，上限 160px
library;

import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:flutter/material.dart';

import '../../../../../framework/domain/chat_message.dart';
import '../../../../../framework/protocol/message/attachment.dart';
import 'base/message_render_strategy.dart';

class StickerMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final asset = message.payload?.asset;
    if (asset?.url?.isNotEmpty == true) {
      return _buildSticker(context, asset!);
    }

    // 纯 Unicode emoji 回退：保持原有大号文字渲染
    final content = message.payload?.content ?? message.content;
    if (content.isNotEmpty) {
      return Text(content, style: const TextStyle(fontSize: 48));
    }
    return const SizedBox.shrink();
  }

  Widget _buildSticker(BuildContext context, Attachment asset) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final size = _resolveStickerSize(asset);
    return CachedNetworkImageView(
      imageUrl: asset.url!,
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
      memCacheWidth: (size.width * dpr).round(),
      memCacheHeight: (size.height * dpr).round(),
      placeholder: (context, url) => Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      filterQuality: FilterQuality.medium,
    );
  }

  /// 表情图片尺寸：默认 96×96，按附件宽高等比缩放，最大边 120px，最小边 48px
  Size _resolveStickerSize(Attachment asset) {
    const maxSide = 120.0;
    const minSide = 48.0;
    const defaultSide = 96.0;

    final rawWidth = asset.width;
    final rawHeight = asset.height;
    if (rawWidth == null ||
        rawHeight == null ||
        rawWidth <= 0 ||
        rawHeight <= 0) {
      return const Size(defaultSide, defaultSide);
    }

    final aspect = rawWidth / rawHeight;
    if (aspect >= 1) {
      return Size(maxSide, (maxSide / aspect).clamp(minSide, maxSide));
    }
    return Size((maxSide * aspect).clamp(minSide, maxSide), maxSide);
  }
}
