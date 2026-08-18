// 记事本卡片预览页面
//
// 展示分享到聊天的记事本快照卡片内容（标题 + 更新时间 + 纯文本快照）。
// 若当前用户是卡片所有者，额外提供「打开笔记」入口深链到记事本页面。
import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../note/presentation/pages/note_page.dart';
/// 记事本卡片预览页。
///
/// [card] 为聊天消息中的 [CardPayload]（cardType='note'）。
class NoteCardPreviewPage extends ConsumerWidget {
  final CardPayload card;

  const NoteCardPreviewPage({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final content = card.properties['content'] ?? card.displaySummary;
    final ownerId = int.tryParse(card.properties['ownerId'] ?? '');
    final noteId = int.tryParse(card.entityId ?? '');
    final updatedMs = int.tryParse(card.properties['updatedAt'] ?? '');
    final currentUserId = ref.read(authControllerProvider).value?.userId;
    final isOwner = ownerId != null &&
        ownerId > 0 &&
        ownerId == currentUserId &&
        noteId != null;

    return Scaffold(
      appBar: AppBar(title: Text('note_card_preview'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNote01,
            size: 44,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            card.displayTitle.isEmpty ? 'note_untitled'.tr() : card.displayTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (updatedMs != null && updatedMs > 0) ...[
            const SizedBox(height: 6),
            Text(
              DateUtil.formatTime(updatedMs),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              content.isEmpty ? 'note_card_no_content'.tr() : content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: content),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('note_card_copy_done'.tr())),
                );
              }
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCopy01,
              size: 18,
            ),
            label: Text('note_card_copy'.tr()),
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openNote(context, noteId),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUpRight01,
                size: 18,
              ),
              label: Text('note_card_open'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  void _openNote(BuildContext context, int noteId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotesPage(initialNoteId: noteId),
      ),
    );
  }
}
