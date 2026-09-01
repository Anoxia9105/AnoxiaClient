/// 聊天 AI 助手气泡辅助组件
///
/// 从 [chat_ai_assist_popup.dart] 抽离的展示层 helper widgets，
/// 保持中文注释与原有视觉一致。
library;

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 翻译目标语言列表（与原 _translateLangs 一致，公开供外部复用）
const chatAiAssistTranslateLangs = <String>['中文', 'English', '日本語', '한국어', 'Français'];

// ---------------------------------------------------------------------------
// 通用 Chip
// ---------------------------------------------------------------------------

/// 通用胶囊 Chip（原 _chip）
class ChatAiAssistChip extends StatelessWidget {
  const ChatAiAssistChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    required this.colorScheme,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      hoverColor: colorScheme.primary.withValues(alpha: .08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          color: selected ? colorScheme.primaryContainer.withValues(alpha: .6) : null,
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: .5)
                : colorScheme.outlineVariant.withValues(alpha: .7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// 顶部标题区（原 _buildHeader）
class ChatAiAssistHeader extends StatelessWidget {
  const ChatAiAssistHeader({
    super.key,
    required this.scopeText,
    required this.colorScheme,
    required this.onClose,
  });

  final String scopeText;
  final ColorScheme colorScheme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer.withValues(alpha: .18), colorScheme.surfaceContainerLow.withValues(alpha: 0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 14, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('chat_ai.assist_title'.tr(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                Text(scopeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.primary)),
              ],
            ),
          ),
          ChatAiAssistIconButton(
            icon: HugeIcons.strokeRoundedCancel01,
            tooltip: 'close'.tr(),
            onTap: onClose,
            colorScheme: colorScheme,
            padding: const EdgeInsets.all(3),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action / Lang Chips
// ---------------------------------------------------------------------------

/// 动作 chips 行（原 _buildActionChips）
class ChatAiAssistActionChips extends StatelessWidget {
  const ChatAiAssistActionChips({
    super.key,
    required this.selectedAction,
    required this.streaming,
    required this.colorScheme,
    required this.onSelectPolish,
    required this.onSelectExpand,
    required this.onSelectContinue,
    required this.onSelectTranslate,
    required this.onSelectSimplify,
    required this.onSelectCustom,
  });

  final String? selectedAction;
  final bool streaming;
  final ColorScheme colorScheme;
  final VoidCallback? onSelectPolish;
  final VoidCallback? onSelectExpand;
  final VoidCallback? onSelectContinue;
  final VoidCallback? onSelectTranslate;
  final VoidCallback? onSelectSimplify;
  final VoidCallback? onSelectCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ChatAiAssistChip(
          label: 'chat_ai.polish'.tr(),
          onTap: streaming ? null : onSelectPolish,
          selected: selectedAction == 'polish',
          colorScheme: colorScheme,
        ),
        ChatAiAssistChip(
          label: 'chat_ai.expand'.tr(),
          onTap: streaming ? null : onSelectExpand,
          selected: selectedAction == 'expand',
          colorScheme: colorScheme,
        ),
        ChatAiAssistChip(
          label: 'chat_ai.continue'.tr(),
          onTap: streaming ? null : onSelectContinue,
          selected: selectedAction == 'continueWrite',
          colorScheme: colorScheme,
        ),
        ChatAiAssistChip(
          label: 'chat_ai.translate'.tr(),
          onTap: streaming ? null : onSelectTranslate,
          selected: selectedAction == 'translate',
          colorScheme: colorScheme,
        ),
        ChatAiAssistChip(
          label: 'chat_ai.simplify'.tr(),
          onTap: streaming ? null : onSelectSimplify,
          selected: selectedAction == 'simplify',
          colorScheme: colorScheme,
        ),
        ChatAiAssistChip(
          label: 'chat_ai.custom'.tr(),
          onTap: streaming ? null : onSelectCustom,
          selected: selectedAction == 'custom',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

/// 语言 chips 行（原 _buildLangChips）
class ChatAiAssistLangChips extends StatelessWidget {
  const ChatAiAssistLangChips({
    super.key,
    required this.selectedLang,
    required this.colorScheme,
    required this.onSelectLang,
  });

  final String selectedLang;
  final ColorScheme colorScheme;
  final ValueChanged<String> onSelectLang;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final lang in chatAiAssistTranslateLangs)
          ChatAiAssistChip(
            label: lang,
            onTap: () => onSelectLang(lang),
            selected: selectedLang == lang,
            colorScheme: colorScheme,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 自定义指令输入
// ---------------------------------------------------------------------------

/// 自定义指令输入行（原 build 中自定义指令部分的 Row）
class ChatAiAssistCustomInput extends StatelessWidget {
  const ChatAiAssistCustomInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'chat_ai.custom_hint'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: enabled ? onSubmit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
            ),
            child: Text('note_ai.run'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview / Skeleton
// ---------------------------------------------------------------------------

/// 预览区域（原 _buildPreviewArea）
class ChatAiAssistPreviewArea extends StatelessWidget {
  const ChatAiAssistPreviewArea({
    super.key,
    required this.preview,
    required this.streaming,
    required this.thinking,
    required this.colorScheme,
    required this.onCopy,
  });

  final String preview;
  final bool streaming;
  final String? thinking;
  final ColorScheme colorScheme;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final empty = preview.isEmpty && !streaming;
    final isStreaming = streaming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 11, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('ai_preview_label'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                ],
              ),
            ),
            const Spacer(),
            if (!empty)
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(RadiusToken.sm),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 56, maxHeight: 240),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
                color: empty ? colorScheme.outlineVariant.withValues(alpha: .5) : colorScheme.primary.withValues(alpha: .18)),
            boxShadow: empty
                ? null
                : [BoxShadow(color: colorScheme.primary.withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: empty
                ? Center(
                    key: const ValueKey('empty_chat'),
                    child: Text('chat_ai.preview_empty'.tr(),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  )
                : isStreaming && preview.isEmpty
                    ? ChatAiAssistSkeleton(key: const ValueKey('streaming'), thinking: thinking, colorScheme: colorScheme)
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

/// 流式骨架（原 _buildSkeleton）
class ChatAiAssistSkeleton extends StatelessWidget {
  const ChatAiAssistSkeleton({
    super.key,
    this.thinking,
    required this.colorScheme,
  });

  final String? thinking;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 200, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 160, height: 11),
        const SizedBox(height: 12),
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 180, height: 11),
        if (thinking != null && thinking!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(thinking!,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: .6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Apply Row
// ---------------------------------------------------------------------------

/// 应用结果操作行（原 _buildApplyRow）
class ChatAiAssistApplyRow extends StatelessWidget {
  const ChatAiAssistApplyRow({
    super.key,
    required this.hasSelectionRange,
    required this.copiedTick,
    required this.colorScheme,
    required this.onApplyToSelection,
    required this.onInsertAtCursor,
    required this.onReplaceAll,
    required this.onRetry,
    required this.onCopy,
  });

  final bool hasSelectionRange;
  final bool copiedTick;
  final ColorScheme colorScheme;
  final VoidCallback onApplyToSelection;
  final VoidCallback onInsertAtCursor;
  final VoidCallback onReplaceAll;
  final VoidCallback onRetry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasSelectionRange)
          ChatAiAssistApplyButton(
            label: 'chat_ai.replace_selection'.tr(),
            onTap: onApplyToSelection,
            filled: true,
            colorScheme: colorScheme,
          )
        else ...[
          ChatAiAssistApplyButton(
            label: 'chat_ai.insert_cursor'.tr(),
            onTap: onInsertAtCursor,
            filled: true,
            colorScheme: colorScheme,
          ),
          ChatAiAssistApplyButton(
            label: 'chat_ai.replace_all'.tr(),
            onTap: onReplaceAll,
            colorScheme: colorScheme,
          ),
        ],
        ChatAiAssistApplyButton(
          label: 'chat_ai.retry'.tr(),
          onTap: onRetry,
          colorScheme: colorScheme,
        ),
        ChatAiAssistIconButton(
          icon: copiedTick ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedCopy01,
          tooltip: 'chat_ai.copy'.tr(),
          onTap: onCopy,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

/// 应用按钮（原 _applyBtn）
class ChatAiAssistApplyButton extends StatelessWidget {
  const ChatAiAssistApplyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
    required this.colorScheme,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(RadiusToken.md),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: filled ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// 小图标按钮（原 _iconBtn / _miniIconBtn）
class ChatAiAssistIconButton extends StatelessWidget {
  const ChatAiAssistIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colorScheme,
    this.padding = const EdgeInsets.all(4),
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        child: Padding(
          padding: padding,
          child: HugeIcon(icon: icon, size: 14, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
