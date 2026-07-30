/// 卡片消息渲染策略
///
/// 实现卡片类型消息的渲染逻辑，将 CardPayload 数据渲染为可点击的卡片组件。
/// 支持联系人卡片和群组卡片的识别与跳转。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/features/contact/presentation/pages/recommended_contact_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/group_card_preview_page.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'base/message_render_strategy.dart';

/// 卡片消息渲染策略
///
/// 处理 [CardPayload] 类型消息的渲染，将卡片数据展示为包含标题、
/// 摘要、缩略图的可点击卡片。支持跳转到联系人详情页或群组预览页。
class CardMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final card = message.payload?.card;
    if (card == null) {
      final fallback = message.payload?.content ?? message.content;
      return Text(fallback, style: TextStyle(color: textColor, fontSize: 15));
    }

    return _CardMessage(card: card);
  }
}

class _CardMessage extends StatelessWidget {
  final CardPayload card;

  const _CardMessage({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = card.displayTitle;
    final summary = card.displaySummary;
    final thumbnailUrl = card.thumbnailUrl?.trim();
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    final isContactCard =
        card.cardType == 'contact' && int.tryParse(card.entityId ?? '') != null;
    final isGroupCard =
        card.cardType == 'group' && card.entityId?.isNotEmpty == true;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isContactCard || isGroupCard
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => isGroupCard
                      ? GroupCardPreviewPage(roomId: card.entityId!)
                      : RecommendedContactDetailPage(card: card),
                ),
              )
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320, minWidth: 220),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CardThumbnail(url: hasThumbnail ? thumbnailUrl : null),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : '[card]',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (card.cardType?.isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Text(
                          isContactCard
                              ? 'contact_card_label'.tr()
                              : (isGroupCard
                                    ? 'group_card_label'.tr()
                                    : card.cardType!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardThumbnail extends StatelessWidget {
  final String? url;

  const _CardThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 52,
        height: 52,
        color: colorScheme.surface,
        alignment: Alignment.center,
        child: imageUrl == null
            ? Icon(
                Icons.badge_outlined,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              )
            : Image.network(
                imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.badge_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
