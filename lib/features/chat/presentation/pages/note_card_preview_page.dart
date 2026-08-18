// 记事本卡片预览页面
//
// 展示分享到聊天的记事本快照卡片内容（标题 + 更新时间 + 纯文本快照）。
// 若当前用户是卡片所有者，额外提供「打开笔记」入口深链到记事本页面。
import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/note/note_open_provider.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../note/presentation/pages/note_page.dart';
import '../../../note/presentation/widgets/note_card_content.dart';

/// 记事本卡片预览页。
///
/// [card] 为聊天消息中的 [CardPayload]（cardType='note'）。
class NoteCardPreviewPage extends ConsumerWidget {
  final CardPayload card;

  const NoteCardPreviewPage({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = resolveNoteCardContent(card);
    final ownerId = int.tryParse(card.properties['ownerId'] ?? '');
    final noteId = int.tryParse(card.entityId ?? '');
    final updatedMs = int.tryParse(card.properties['updatedAt'] ?? '');
    final currentUserId = ref.watch(authControllerProvider).value?.userId;
    final isOwner = ownerId != null &&
        ownerId > 0 &&
        ownerId == currentUserId &&
        noteId != null;

    return Scaffold(
      // 背景显式取自主题色，保证明暗主题与自定义背景设置下页面观感一致
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('note_card_preview'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNote01,
            size: 44,
            color: colorScheme.primary,
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
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: .55),
                  colorScheme.surfaceContainerLow.withValues(alpha: .7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: .5),
              ),
            ),
            child: SelectableText(
              content.isEmpty ? 'note_card_no_content'.tr() : content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (!context.mounted) return;
              Toast.showToast(
                'note_card_copy_done'.tr(),
                type: ToastType.success,
              );
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
              onPressed: () => _openNote(context, ref, noteId),
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

  void _openNote(BuildContext context, WidgetRef ref, int noteId) {
    if (DeviceUtil.isMobile(context)) {
      // 移动端：压栈全屏编辑器页（自带返回键）
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotesPage(initialNoteId: noteId),
        ),
      );
      return;
    }
    // 桌面端：记事本常驻侧边栏，切换侧边栏并打开笔记，避免压栈新页面无法返回
    ref.read(noteOpenRequestProvider.notifier).state = noteId;
    ref.read(layoutControllerProvider.notifier).setToNotes();
    Navigator.of(context).pop();
  }
}
