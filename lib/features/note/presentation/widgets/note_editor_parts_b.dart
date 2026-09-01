/// 斜杠命令菜单浮层 / 标题区 / 状态栏
///
/// 从 note_editor_parts.dart 拆出，均为公开部件（super.key），保留中文注释与文案
library;

import 'dart:math' as math;

import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_editor_parts_a.dart';
import 'note_editor_widgets.dart';
import 'note_tags_dialog.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

// ======================= 斜杠菜单浮层 =======================

/// 斜杠命令菜单浮层
///
/// 根据锚点与屏幕尺寸自动计算弹出位置，支持空态与键盘选中高亮。
class NoteSlashMenuOverlay extends StatelessWidget {
  final List<SlashCommand> commands;
  final Offset? anchor;
  final double lineHeight;
  final int selectedIndex;
  final ScrollController scrollController;
  final ValueChanged<SlashCommand> onSelected;
  final VoidCallback onPointerEnter;
  final VoidCallback onPointerExit;

  const NoteSlashMenuOverlay({
    super.key,
    required this.commands,
    required this.anchor,
    required this.lineHeight,
    required this.selectedIndex,
    required this.scrollController,
    required this.onSelected,
    required this.onPointerEnter,
    required this.onPointerExit,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      const popupWidth = 268.0;
      const maxPopupHeight = 300.0;
      final media = MediaQuery.of(context);
      final screen = media.size;
      final screenWidth = screen.width;
      // 键盘弹起时可视高度要扣除输入法占用区域，否则菜单会被键盘挡住
      final screenHeight = screen.height - media.viewInsets.bottom;
      final a = anchor ?? Offset.zero;
      final lh = lineHeight <= 0 ? 24.0 : lineHeight;

      var left = a.dx;
      if (left + popupWidth > screenWidth - 8) {
        left = math.max(8.0, screenWidth - popupWidth - 8);
      }
      if (left < 8) left = 8;

      final contentHeight = commands.isEmpty
          ? 56.0
          : math.min(maxPopupHeight, commands.length * 43.0 + 8);
      var top = a.dy + lh + 4;
      if (top + contentHeight > screenHeight - 8) {
        top = math.max(8.0, a.dy - contentHeight - 4);
      }
      if (top < 8) top = 8;

      return Positioned(
        left: left,
        top: top,
        width: popupWidth,
        child: MouseRegion(
          // 记录指针是否在菜单内：桌面端点击菜单项会让编辑器失焦，
          // 失焦监听据此跳过关闭菜单，保证 onTap 能正常触发
          onEnter: (_) => onPointerEnter(),
          onExit: (_) => onPointerExit(),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            color: colorScheme.surface,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              child: commands.isEmpty
                  ? SizedBox(
                      height: contentHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearchRemove,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'note_slash_no_result'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: contentHeight,
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemExtent: 43.0,
                        itemCount: commands.length,
                        itemBuilder: (context, index) {
                          final cmd = commands[index];
                          return Column(
                            children: [
                              Expanded(
                                child: SlashCommandItem(
                                  label: cmd.labelKey.tr(),
                                  icon: cmd.icon,
                                  selected: index == selectedIndex,
                                  onTap: () => onSelected(cmd),
                                ),
                              ),
                              if (index < commands.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  indent: 40,
                                  endIndent: 8,
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: .4,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
      );
    } catch (_) {
      // 菜单构建异常时退化为空白，绝不抛给 Overlay / 编辑区
      return const SizedBox.shrink();
    }
  }
}

// ======================= 标题区 =======================

/// 标题区：标题输入框 + 标签编辑入口，下方展示当前笔记标签（可点击按标签检索）
class NoteEditorTitleArea extends ConsumerWidget {
  final NoteEditSession session;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onTitleSubmitted;
  final VoidCallback onSaveNow;

  const NoteEditorTitleArea({
    super.key,
    required this.session,
    required this.titleController,
    required this.onTitleChanged,
    required this.onTitleSubmitted,
    required this.onSaveNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags =
        ref.watch(noteTreeServiceProvider).value?.findNote(session.noteId)?.tags ??
        const <String>[];
    final activeTag = ref.watch(noteTagFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: NoteEditorTitleField(
                controller: titleController,
                onChanged: onTitleChanged,
                onSubmitted: onTitleSubmitted,
                onSaveNow: onSaveNow,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'note_tags'.tr(),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: () => showNoteTagsDialog(
                context,
                noteId: session.noteId,
                initialTags: tags,
              ),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedTag01,
                size: 17,
                color: activeTag != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final name in tags)
                EditorTagChip(
                  label: name,
                  selected: activeTag == name,
                  onTap: () => ref.read(noteTagFilterProvider.notifier).state =
                      activeTag == name ? null : name,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 标题输入框：默认无边框、高度更高，聚焦时显示圆角边框。
class NoteEditorTitleField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSaveNow;

  const NoteEditorTitleField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSaveNow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      onFocusChange: (hasFocus) {
        // 标题失焦时立即保存，不用等 1.5s 防抖
        if (!hasFocus) onSaveNow();
      },
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          hintText: 'note_untitled'.tr(),
          hintStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

// ======================= 状态栏 =======================

String formatNoteTime(DateTime? dt) {
  if (dt == null) return '--:--:--';
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final ss = dt.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

/// 底部状态栏：保存状态 / 分享 / 导入导出 / 版本 / 字数统计
class NoteEditorStatusBar extends StatelessWidget {
  final NoteEditSession session;
  final int wordCount;
  final Future<void> Function() onSaveRetry;
  final Future<void> Function(BuildContext context) onShare;
  final Future<void> Function(BuildContext context) onImportMarkdown;
  final Future<void> Function(BuildContext context) onExportMarkdown;
  final Future<void> Function(BuildContext context) onExportPdf;
  final Future<void> Function(BuildContext context) onShowVersions;

  const NoteEditorStatusBar({
    super.key,
    required this.session,
    required this.wordCount,
    required this.onSaveRetry,
    required this.onShare,
    required this.onImportMarkdown,
    required this.onExportMarkdown,
    required this.onExportPdf,
    required this.onShowVersions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final saveLabel = switch (session.saveState) {
      NoteSaveState.saving => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 6),
          Text(
            'note_autosave_saving'.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      NoteSaveState.saved => Text(
        'note_autosave_saved'.tr(args: [formatNoteTime(session.lastSavedAt)]),
        style: const TextStyle(fontSize: 12),
      ),
      NoteSaveState.failed => TextButton.icon(
        onPressed: () => onSaveRetry().catchError((Object _) => false),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 13),
        label: Text(
          'note_autosave_failed'.tr(),
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      NoteSaveState.idle => Text(
        'note_autosave_idle'.tr(),
        style: const TextStyle(fontSize: 12),
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: saveLabel),
          IconButton(
            tooltip: 'note_share'.tr(),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => onShare(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'note_markdown_import'.tr(),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => onImportMarkdown(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFileImport,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'note_markdown_export'.tr(),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => onExportMarkdown(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFileExport,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'note_pdf_export'.tr(),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => onExportPdf(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPdf01,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'note_versions'.tr(),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => onShowVersions(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'note_word_count'.tr(args: [wordCount.toString()]),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
