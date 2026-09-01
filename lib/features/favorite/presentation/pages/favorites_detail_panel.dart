import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';
import 'package:anoxia/features/note/presentation/widgets/note_card_content.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'favorites_common.dart';
import 'favorites_detail_widgets.dart';
import 'favorites_list_panel.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 收藏详情面板组件
class FavoriteDetailPanel extends StatelessWidget {
  /// 收藏项对象
  final ChatFavorite item;

  /// 取消收藏回调
  final VoidCallback onDelete;

  const FavoriteDetailPanel({super.key, required this.item, required this.onDelete});

  /// 是否为适合引文卡展示的短文本（单行且不超过 120 字符）
  bool _isRefinedTextDetail(ChatMessage message, String detailText) {
    if (message.messageType != MessageType.text) return false;

    final text = detailText.trim();
    if (text.isEmpty) return false;
    if (text.contains('\n')) return false;

    return text.length <= 120;
  }

  /// 媒体消息的说明文字（图片/视频/文件附带的 caption）
  String? _captionOf(ChatMessage message) {
    final type = message.messageType;
    if (type != MessageType.image &&
        type != MessageType.video &&
        type != MessageType.file) {
      return null;
    }
    final caption = message.payload?.content?.trim() ?? '';
    if (caption.isEmpty || isPlaceholderSummary(caption)) return null;
    return caption;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final message = item.toChatMessage();
    final type = message.messageType ?? MessageType.text;
    final strategy = MessageRenderFactory.getStrategy(message.messageType);
    final detailFallback = item.detailText;
    final hasRenderableBody =
        (message.payload?.content?.trim().isNotEmpty ?? false) ||
        (message.payload?.quillDelta?.trim().isNotEmpty ?? false) ||
        (message.payload?.mediaAttachments.isNotEmpty ?? false);
    final isRefinedTextDetail = _isRefinedTextDetail(message, detailFallback);
    final style = favoriteTypeStyle(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: 14,
                    child: HugeIcon(
                      icon: style.icon,
                      size: 13,
                      color: favoriteTypeColor(context, type),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'chat_favorite'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        FavoriteTypeChip(type: type),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.senderAvatar.isNotEmpty ||
                            item.senderDisplayName.isNotEmpty) ...[
                          AvatarWidget(
                            size: 18,
                            url: item.senderAvatar,
                            name: item.senderDisplayName,
                            borderRadius: 9,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            item.senderDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.senderDisplayName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            formatFavoriteDate(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'chat_copy'.tr(),
                onPressed: () async {
                  final copyText = detailFallback.trim().isNotEmpty
                      ? displayFavoriteSummary(item, detailFallback)
                      : displayFavoriteSummary(item, item.summary);
                  await Clipboard.setData(ClipboardData(text: copyText));
                  if (!context.mounted) return;
                  Toast.showToast(
                    'chat_copy_success'.tr(),
                    type: ToastType.success,
                  );
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCopy01,
                  size: 17,
                ),
              ),
              IconButton(
                tooltip: 'favorite_remove'.tr(),
                onPressed: onDelete,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: _buildDetailBody(
              context,
              message,
              strategy,
              detailFallback,
              hasRenderableBody,
              isRefinedTextDetail,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBody(
    BuildContext context,
    ChatMessage message,
    MessageRenderStrategy strategy,
    String detailFallback,
    bool hasRenderableBody,
    bool isRefinedTextDetail,
  ) {
    final cs = Theme.of(context).colorScheme;

    // 短文本：引文卡片
    if (isRefinedTextDetail) {
      return FavoriteTextDetailCard(
        text: detailFallback,
        senderName: item.senderDisplayName,
        dateLabel: formatFavoriteDate(item.createdAt),
      );
    }

    // 记事本卡片：展示完整快照内容（标题 + 更新时间 + 多行正文）
    final card = message.payload?.card;
    if (card?.cardType == 'note') {
      return FavoriteNoteDetailCard(
        title: card!.displayTitle.isEmpty
            ? 'note_untitled'.tr()
            : card.displayTitle,
        updatedMs: int.tryParse(card.properties['updatedAt'] ?? ''),
        content: resolveNoteCardContent(card),
      );
    }

    // 纯文本：可选中文本卡片
    if (message.messageType == MessageType.text) {
      return TextDetailCard(
        text: detailFallback.isEmpty
            ? 'favorite_empty_placeholder'.tr()
            : detailFallback,
      );
    }

    // 媒体 / 富文本：策略渲染 + 可选说明文字
    if (hasRenderableBody) {
      final caption = _captionOf(message);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FavoriteContentCard(
            child: strategy.buildContent(context, message, cs.onSurface),
          ),
          if (caption != null) ...[
            const SizedBox(height: 12),
            TextDetailCard(text: caption),
          ],
        ],
      );
    }

    return TextDetailCard(
      text: displayFavoriteSummary(item, detailFallback).isEmpty
          ? 'favorite_empty_placeholder'.tr()
          : displayFavoriteSummary(item, detailFallback),
    );
  }
}

