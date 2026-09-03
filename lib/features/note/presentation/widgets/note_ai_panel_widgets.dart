/// 记事本 AI 面板展示组件（面板侧边栏专用）
///
/// 从 `note_ai_panel.dart` 抽取，原为 `_NoteAiPanelState` 私有方法
/// ` _buildPreviewArea` / `_buildActionsRow` / `_buildSkeleton`，
/// 现公开为可复用 StatelessWidget，并统一添加 `super.key`。
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';

import 'note_ai_langs.dart';
import 'note_ai_panel_action.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// AI 能力选择器：ChoiceChip + 自定义指令输入 / 翻译语言下拉
class NoteAiPanelActionSelector extends StatelessWidget {
  const NoteAiPanelActionSelector({
    super.key,
    required this.action,
    required this.streaming,
    required this.onSelected,
    required this.instructionCtrl,
    required this.targetLang,
    required this.onLangChanged,
  });

  final AiPanelAction? action;
  final bool streaming;
  final ValueChanged<AiPanelAction> onSelected;
  final TextEditingController instructionCtrl;
  final String targetLang;
  final ValueChanged<String?> onLangChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('note_ai_capabilities'.tr(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith( fontWeight: FontWeight.w600, letterSpacing: .4, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in AiPanelAction.values)
              ChoiceChip(
                label: Text(a.label, style: Theme.of(context).textTheme.bodySmall!.copyWith( fontWeight: FontWeight.w500)),
                avatar: HugeIcon(
                    icon: a.icon, size: 14, color: action == a ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                selected: action == a,
                selectedColor: cs.primaryContainer,
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .6),
                side: BorderSide(
                    color: action == a ? cs.primary.withValues(alpha: .4) : cs.outlineVariant.withValues(alpha: .6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.pill)),
                showCheckmark: false,
                onSelected: streaming ? null : (_) => onSelected(a),
              ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: action == AiPanelAction.custom
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    key: const ValueKey('custom_field'),
                    controller: instructionCtrl,
                    enabled: !streaming,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'note_ai.instruction_hint'.tr(),
                      hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith( color: cs.onSurfaceVariant.withValues(alpha: .7)),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
                          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .6))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
                          borderSide: BorderSide(color: cs.primary, width: 1.4)),
                    ),
                  ),
                )
              : action == AiPanelAction.translate
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('lang_field'),
                        initialValue: targetLang,
                        isDense: true,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'note_ai.target_lang'.tr(),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(RadiusToken.lg),
                              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .6))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(RadiusToken.lg),
                              borderSide: BorderSide(color: cs.primary, width: 1.4)),
                        ),
                        items: [
                          for (final lang in noteTranslateLangs)
                            DropdownMenuItem(value: lang, child: Text(lang, style: const TextStyle(fontSize: 13))),
                        ],
                        onChanged: streaming ? null : onLangChanged,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}

/// 预览区：标题 + 预览容器（空态 / 骨架 / Markdown）
class NoteAiPanelPreviewArea extends StatelessWidget {
  const NoteAiPanelPreviewArea({
    super.key,
    required this.preview,
    required this.streaming,
    this.thinking,
    required this.onCopy,
  });

  final String preview;
  final bool streaming;
  final String? thinking;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final empty = preview.isEmpty;
    final isStreaming = streaming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
                border: Border.all(color: cs.primary.withValues(alpha: .15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 12, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('ai_preview_label'.tr(), style: Theme.of(context).textTheme.labelSmall!.copyWith( fontWeight: FontWeight.w600, color: cs.primary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isStreaming && !empty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(RadiusToken.sm),
                ),
                child: Text('note_ai_word_count'.tr(args: [preview.length.toString()]), style: Theme.of(context).textTheme.labelSmall!.copyWith( color: cs.onTertiaryContainer)),
              ),
            const Spacer(),
            if (!empty)
              IconButton(
                tooltip: 'note_ai.copy'.tr(),
                visualDensity: VisualDensity.compact,
                onPressed: onCopy,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 16, color: cs.onSurfaceVariant),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 140, maxHeight: 320),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            border: Border.all(
                color: empty ? cs.outlineVariant.withValues(alpha: .35) : cs.primary.withValues(alpha: isStreaming ? .25 : .0),
                width: 1),
            boxShadow: empty
                ? null
                : [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: .06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: empty && isStreaming
                ? NoteAiPanelSkeleton(thinking: thinking, key: const ValueKey('generating'))
                : empty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
                              ),
                              child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedSparkles,
                                  size: 22,
                                  color: cs.onSurfaceVariant.withValues(alpha: .6)),
                            ),
                            const SizedBox(height: 10),
                            Text('note_ai.preview_empty'.tr(),
                                style: Theme.of(context).textTheme.bodySmall!.copyWith( color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('note_ai_choose_action_hint'.tr(),
                                style: Theme.of(context).textTheme.labelSmall!.copyWith( color: cs.onSurfaceVariant.withValues(alpha: .6))),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        key: ValueKey('content_${preview.hashCode}'),
                        child: AiMarkdownPreview(data: preview),
                      ),
          ),
        ),
      ],
    );
  }
}

/// 操作区：运行按钮 + 结果后续操作（替换/追加/设为标题）或失败提示
class NoteAiPanelActionsRow extends StatelessWidget {
  const NoteAiPanelActionsRow({
    super.key,
    required this.preview,
    required this.streaming,
    required this.failed,
    required this.action,
    required this.selStart,
    required this.onRun,
    required this.onReplaceAll,
    required this.onAppendToEnd,
    required this.onReplaceSelection,
    required this.onApplyAsTitle,
  });

  final String preview;
  final bool streaming;
  final bool failed;
  final AiPanelAction? action;
  final int? selStart;
  final VoidCallback onRun;
  final VoidCallback onReplaceAll;
  final VoidCallback onAppendToEnd;
  final VoidCallback onReplaceSelection;
  final VoidCallback onApplyAsTitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasResult = preview.isNotEmpty && !streaming;
    if (streaming) {
      return SizedBox(
        height: 44,
        child: FilledButton.icon(
          onPressed: null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
            disabledBackgroundColor: cs.surfaceContainerHighest,
            disabledForegroundColor: cs.onSurfaceVariant,
          ),
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          label: Text('note_ai.generating'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: (action == null) ? null : onRun,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
              elevation: action == null ? 0 : 2,
              shadowColor: cs.primary.withValues(alpha: .35),
            ),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 16,
              color: (action == null) ? cs.onSurface.withValues(alpha: .4) : cs.onPrimary,
            ),
            label: Text('note_ai.run'.tr(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith( fontWeight: FontWeight.w700, letterSpacing: .2, color: (action == null) ? cs.onSurface.withValues(alpha: .4) : cs.onPrimary)),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: hasResult && action != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 1, color: cs.outlineVariant.withValues(alpha: .4)),
                      const SizedBox(height: 12),
                      if (action == AiPanelAction.title)
                        SizedBox(
                          height: 40,
                          child: FilledButton.tonalIcon(
                            onPressed: onApplyAsTitle,
                            icon: HugeIcon(icon: HugeIcons.strokeRoundedText, size: 16, color: cs.primary),
                            label: Text('note_ai.use_as_title'.tr()),
                          ),
                        )
                      else ...[
                        if ((action == AiPanelAction.continueWrite || action == AiPanelAction.expand) &&
                            selStart == null)
                          SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: onAppendToEnd,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedNoteAdd, size: 16, color: cs.primary),
                              label: Text('note_ai.append'.tr()),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
                                side: BorderSide(color: cs.outlineVariant.withValues(alpha: .7)),
                              ),
                            ),
                          ),
                        if ((action == AiPanelAction.continueWrite || action == AiPanelAction.expand) &&
                            selStart == null)
                          const SizedBox(height: 8),
                        if (selStart != null &&
                            (action == AiPanelAction.polish ||
                                action == AiPanelAction.translate ||
                                action == AiPanelAction.custom))
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: onReplaceSelection,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 16, color: cs.onPrimary),
                              label: Text('note_ai.replace_selection'.tr()),
                              style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg))),
                            ),
                          )
                        else if (selStart == null)
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: onReplaceAll,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedFileEdit, size: 16, color: cs.onPrimary),
                              label: Text('note_ai.replace_all'.tr()),
                              style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg))),
                            ),
                          ),
                      ],
                    ],
                  ),
                )
              : failed
                  ? Padding(
                      key: const ValueKey('failed'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
                          border: Border.all(color: cs.error.withValues(alpha: .3)),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 16, color: cs.error),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('note_ai.failed'.tr(),
                                    style: TextStyle(color: cs.error, fontSize: 12, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
        ),
      ],
    );
  }
}

/// 骨架屏：生成中占位
class NoteAiPanelSkeleton extends StatelessWidget {
  const NoteAiPanelSkeleton({super.key, this.thinking});

  final String? thinking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 220, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 160, height: 12),
        const SizedBox(height: 16),
        const SkeletonLine(width: double.infinity, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 190, height: 12),
        if (thinking != null && thinking!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(thinking!,
              style: Theme.of(context).textTheme.labelSmall!.copyWith( color: cs.onSurfaceVariant.withValues(alpha: .6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}
