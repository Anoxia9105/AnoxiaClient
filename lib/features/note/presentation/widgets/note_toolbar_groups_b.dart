import 'package:anoxia/common/utils/shortcut_hint.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_ai_sheet.dart';
import 'note_quill_actions.dart';
import 'note_toolbar_groups_a.dart';

/// 记事本工具栏分组组件 - 扩展部件
///
/// 包含链接、任务、搜索、AI 及组合分组（颜色 / 行内格式 / 列表 / 历史）。

/// 链接按钮：弹出输入框设置/移除链接
class NoteToolbarLinkButton extends StatelessWidget {
  const NoteToolbarLinkButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.iconColor,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final btnKey = GlobalKey();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isLinked = controller.getSelectionStyle().attributes.containsKey(Attribute.link.key);
        return IconButton(
          key: btnKey,
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_link'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () => noteSetLinkBubble(context, btnKey, controller, focusNode),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedLink01,
            size: 16,
            color: isLinked ? colorScheme.primary : iconColor,
            strokeWidth: isLinked ? 2.5 : 1.5,
          ),
        );
      },
    );
  }
}

/// 任务列表按钮：当前处于任务列表时高亮
class NoteToolbarTaskListButton extends StatelessWidget {
  const NoteToolbarTaskListButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.iconColor,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final listValue = controller.getSelectionStyle().attributes[Attribute.list.key]?.value;
        final isChecked = listValue == Attribute.checked.value;
        final isUnchecked = listValue == Attribute.unchecked.value;
        final isSelected = isChecked || isUnchecked;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: withShortcut('note_task_list'.tr(), shortcut('C', shift: true)),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (isSelected) {
              // 再次点击移除复选框，还原为普通段落
              controller.formatSelection(Attribute.clone(Attribute.list, null));
            } else {
              controller.formatSelection(Attribute.checked);
            }
            focusNode.requestFocus();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCheckList,
            size: 16,
            color: isSelected ? colorScheme.primary : iconColor,
            strokeWidth: isSelected ? 2.5 : 1.5,
          ),
        );
      },
    );
  }
}

/// 查找按钮：点击切换右侧查找面板
class NoteToolbarSearchButton extends StatelessWidget {
  const NoteToolbarSearchButton({
    super.key,
    required this.searchActive,
    required this.onSearchToggle,
    required this.iconColor,
  });

  final bool searchActive;
  final VoidCallback onSearchToggle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: withShortcut('note_search_in_doc'.tr(), shortcut('F')),
      visualDensity: VisualDensity.compact,
      onPressed: onSearchToggle,
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedSearch02,
        size: 16,
        color: searchActive ? colorScheme.primary : iconColor,
        strokeWidth: searchActive ? 2.5 : 1.5,
      ),
    );
  }
}

/// AI 助手按钮：优先走右侧面板互斥模式（与搜索面板互斥），若未提供 onAiToggle 则回退到气泡快捷入口
class NoteToolbarAiButton extends StatelessWidget {
  const NoteToolbarAiButton({
    super.key,
    required this.controller,
    required this.iconColor,
    this.noteId,
    this.onAiTap,
    this.onTitleSelected,
    this.onAiToggle,
    required this.aiActive,
  });

  final QuillController controller;
  final Color iconColor;
  final int? noteId;
  final VoidCallback? onAiTap;
  final ValueChanged<String>? onTitleSelected;
  final VoidCallback? onAiToggle;
  final bool aiActive;

  void _openAiSheet(BuildContext ctx, String? api) {
    showNoteAiSheet(
      ctx,
      controller: controller,
      noteId: noteId,
      initialAction: api,
      onTitle: onTitleSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 新模式：右侧面板互斥（与搜索一致）
    if (onAiToggle != null) {
      return IconButton(
        mouseCursor: SystemMouseCursors.click,
        tooltip: 'note_ai.title'.tr(),
        visualDensity: VisualDensity.compact,
        onPressed: onAiToggle,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedSparkles,
          size: 16,
          color: aiActive ? colorScheme.primary : colorScheme.primary,
          strokeWidth: aiActive ? 2.5 : 1.8,
        ),
      );
    }
    // 兼容旧版：气泡快捷入口
    final btnKey = GlobalKey();
    return IconButton(
      key: btnKey,
      mouseCursor: SystemMouseCursors.click,
      tooltip: 'note_ai.title'.tr(),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        if (onAiTap != null && noteId == null && onTitleSelected == null) {
          onAiTap!.call();
          return;
        }
        Function? close;
        close = showNoteBubble(
          context,
          anchorKey: btnKey,
          maxWidth: 280,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedFileSearch,
                  label: 'note_ai.action_summarize'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'SUMMARIZE');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedBrush,
                  label: 'note_ai.action_polish'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'POLISH');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedExpand,
                  label: 'note_ai.action_expand'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'EXPAND');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedText,
                  label: 'note_ai.action_title'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'TITLE');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedTranslate,
                  label: 'note_ai.action_translate'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'TRANSLATE');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedPen01,
                  label: 'note_ai.action_continue'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'CONTINUE');
                  },
                ),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedMagicWand01,
                  label: 'note_ai.action_custom'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, 'CUSTOM');
                  },
                ),
                const Divider(height: 1, thickness: .5),
                NoteToolbarAiBubbleTile(
                  icon: HugeIcons.strokeRoundedSparkles,
                  label: 'note_ai.title'.tr(),
                  onTap: () {
                    close?.call();
                    _openAiSheet(context, null);
                  },
                ),
              ],
            ),
          ),
        );
      },
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedSparkles,
        size: 16,
        color: colorScheme.primary,
        strokeWidth: 1.8,
      ),
    );
  }
}

/// 颜色按钮组（文字颜色 / 背景色）
class NoteToolbarColorGroup extends StatelessWidget {
  const NoteToolbarColorGroup({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final QuillController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final fgKey = GlobalKey();
    final bgKey = GlobalKey();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChatQuillColorStyleButton(
          key: fgKey,
          controller: controller,
          type: ChatQuillColorStyleType.foreground,
          tooltip: 'toolbar_text_color'.tr(),
          onPressed: () => notePickColorBubble(
            context,
            fgKey,
            controller,
            focusNode,
            background: false,
          ),
        ),
        ChatQuillColorStyleButton(
          key: bgKey,
          controller: controller,
          type: ChatQuillColorStyleType.background,
          tooltip: 'toolbar_bg_color'.tr(),
          onPressed: () => notePickColorBubble(
            context,
            bgKey,
            controller,
            focusNode,
            background: true,
          ),
        ),
      ],
    );
  }
}

/// 行内格式按钮组（粗斜下划线删除线 / 行内代码）
class NoteToolbarInlineGroup extends StatelessWidget {
  const NoteToolbarInlineGroup({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.iconColor,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedTextBold,
          attribute: Attribute.bold,
          tooltip: withShortcut('toolbar_bold'.tr(), shortcut('B')),
          color: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedTextItalic,
          attribute: Attribute.italic,
          tooltip: withShortcut('toolbar_italic'.tr(), shortcut('I')),
          color: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedTextUnderline,
          attribute: Attribute.underline,
          tooltip: withShortcut('toolbar_underline'.tr(), shortcut('U')),
          color: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedTextStrikethrough,
          attribute: Attribute.strikeThrough,
          tooltip: withShortcut('toolbar_strikethrough'.tr(), shortcut('S', shift: true)),
          color: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedSourceCode,
          attribute: Attribute.inlineCode,
          tooltip: withShortcut('toolbar_inline_code'.tr(), shortcut('`')),
          color: iconColor,
        ),
      ],
    );
  }
}

/// 列表按钮组（无序 / 有序 / 任务 / 引用）
class NoteToolbarListGroup extends StatelessWidget {
  const NoteToolbarListGroup({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.iconColor,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedLeftToRightListBullet,
          attribute: Attribute.ul,
          tooltip: withShortcut('note_bullet_list'.tr(), shortcut('L', shift: true)),
          color: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedLeftToRightListNumber,
          attribute: Attribute.ol,
          tooltip: withShortcut('note_ordered_list'.tr(), shortcut('O', shift: true)),
          color: iconColor,
        ),
        NoteToolbarTaskListButton(
          controller: controller,
          focusNode: focusNode,
          iconColor: iconColor,
        ),
        NoteToolbarToggleButton(
          controller: controller,
          focusNode: focusNode,
          icon: HugeIcons.strokeRoundedQuoteDown,
          attribute: Attribute.blockQuote,
          tooltip: withShortcut('toolbar_quote'.tr(), shortcut('B', shift: true)),
          color: iconColor,
        ),
      ],
    );
  }
}

/// 历史操作按钮组（撤销 / 重做 / 清除格式）
class NoteToolbarHistoryGroup extends StatelessWidget {
  const NoteToolbarHistoryGroup({
    super.key,
    required this.controller,
    required this.iconColor,
  });

  final QuillController controller;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteToolbarCustomButton(
          icon: HugeIcons.strokeRoundedUndo,
          tooltip: withShortcut('note_undo'.tr(), shortcut('Z')),
          color: iconColor,
          onPressed: controller.undo,
        ),
        NoteToolbarCustomButton(
          icon: HugeIcons.strokeRoundedRedo,
          tooltip: withShortcut('note_redo'.tr(), shortcut('Y')),
          color: iconColor,
          onPressed: controller.redo,
        ),
        NoteToolbarCustomButton(
          icon: HugeIcons.strokeRoundedTextClear,
          tooltip: 'toolbar_clear_format'.tr(),
          color: iconColor,
          onPressed: () => noteClearFormat(controller),
        ),
      ],
    );
  }
}
