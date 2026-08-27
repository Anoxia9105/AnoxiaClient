import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'favorites_common.dart';
/// 通用内容卡片容器（媒体 / 富文本）
class FavoriteContentCard extends StatelessWidget {
  final Widget child;

  const FavoriteContentCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .5),
            cs.surfaceContainerLow.withValues(alpha: .6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: child,
    );
  }
}

/// 记事本卡片收藏详情：标题 + 更新时间 + 完整快照内容（多行）
class FavoriteNoteDetailCard extends StatelessWidget {
  final String title;
  final int? updatedMs;
  final String content;

  const FavoriteNoteDetailCard({
    super.key,
    required this.title,
    required this.updatedMs,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .55),
            cs.surfaceContainerLow.withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedNote01,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'note_card_label'.tr(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (updatedMs != null && updatedMs! > 0)
                Text(
                  formatFavoriteDate(DateTime.fromMillisecondsSinceEpoch(updatedMs!)),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
          const SizedBox(height: 12),
          SelectableText(
            content.isEmpty ? 'note_card_no_content'.tr() : content,
            style: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

/// 文本内容卡片（可选中复制）
class TextDetailCard extends StatelessWidget {
  final String text;

  const TextDetailCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: SelectableText(
        text,
        style: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurface),
      ),
    );
  }
}

/// 短文本引文卡片
class FavoriteTextDetailCard extends StatelessWidget {
  final String text;
  final String senderName;
  final String dateLabel;

  const FavoriteTextDetailCard({
    super.key,
    required this.text,
    required this.senderName,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .55),
            cs.surfaceContainerLow.withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedQuoteDown,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'favorite_text_type'.tr(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (senderName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— $senderName',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 收藏详情骨架屏
class FavoriteDetailSkeleton extends StatelessWidget {
  const FavoriteDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 42, height: 42, radius: 12),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 120, height: 16),
                  SizedBox(height: 8),
                  SkeletonLine(width: 90, height: 11),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 220, radius: 14),
        ],
      ),
    );
  }
}
