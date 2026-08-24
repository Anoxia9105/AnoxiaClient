import 'package:anoxia/common/utils/shortcut_hint.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_ai_sheet.dart';
import 'note_quill_actions.dart';

/// 记事本富文本工具栏
///
/// 单行流式布局（Wrap）：宽度足够时全部按钮一行显示，放不下时自动换行。
/// 包含：撤销 / 重做 / 清除格式 / 标题级别 / 粗斜下划线删除线 / 行内代码 /
/// 文字颜色 / 背景色 / 查找 / 列表 / 任务 / 引用 / 链接 / 图片 / 对齐。
///
/// 选中态统一：图标加粗（增大 strokeWidth）并以主题色高亮，不带背景色。
class NoteToolbar extends ConsumerWidget {
  final QuillController controller;
  final FocusNode focusNode;

  /// 查找面板是否展开
  final bool searchActive;

  /// 查找按钮点击回调（切换查找面板）
  final VoidCallback onSearchToggle;

  /// AI 助手按钮点击回调（为空则不显示按钮）
  final VoidCallback? onAiTap;

  /// 当前笔记ID（用于 AI 请求在 content 为空时按 noteId 读取）
  final int? noteId;

  /// 标题回填回调（TITLE 动作生成标题时使用）
  final ValueChanged<String>? onTitleSelected;

  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchActive,
    required this.onSearchToggle,
    this.onAiTap,
    this.noteId,
    this.onTitleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      width: double.infinity,
      // 单行流式布局：宽度足够时一行显示，放不下时自动换行
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildCustomBtn(
            HugeIcons.strokeRoundedUndo,
            withShortcut('note_undo'.tr(), shortcut('Z')),
            iconColor,
            controller.undo,
          ),
          _buildCustomBtn(
            HugeIcons.strokeRoundedRedo,
            withShortcut('note_redo'.tr(), shortcut('Y')),
            iconColor,
            controller.redo,
          ),
          _buildCustomBtn(
            HugeIcons.strokeRoundedTextClear,
            'toolbar_clear_format'.tr(),
            iconColor,
            () => noteClearFormat(controller),
          ),
          _buildDivider(context),
          _buildHeaderButton(context, iconColor),
          _buildDivider(context),
          _buildActionButton(
            HugeIcons.strokeRoundedTextBold,
            Attribute.bold,
            withShortcut('toolbar_bold'.tr(), shortcut('B')),
            iconColor,
          ),
          _buildActionButton(
            HugeIcons.strokeRoundedTextItalic,
            Attribute.italic,
            withShortcut('toolbar_italic'.tr(), shortcut('I')),
            iconColor,
          ),
          _buildActionButton(
            HugeIcons.strokeRoundedTextUnderline,
            Attribute.underline,
            withShortcut('toolbar_underline'.tr(), shortcut('U')),
            iconColor,
          ),
          _buildActionButton(
            HugeIcons.strokeRoundedTextStrikethrough,
            Attribute.strikeThrough,
            withShortcut(
              'toolbar_strikethrough'.tr(),
              shortcut('S', shift: true),
            ),
            iconColor,
          ),
          _buildActionButton(
            HugeIcons.strokeRoundedSourceCode,
            Attribute.inlineCode,
            withShortcut('toolbar_inline_code'.tr(), shortcut('`')),
            iconColor,
          ),
          _buildDivider(context),
          // 颜色面板以气泡方式弹出，锚定按钮下方（仿聊天输入框）
          Builder(
            builder: (buttonContext) => ChatQuillColorStyleButton(
              controller: controller,
              type: ChatQuillColorStyleType.foreground,
              tooltip: 'toolbar_text_color'.tr(),
              onPressed: () => notePickColorBubble(
                buttonContext,
                controller,
                focusNode,
                background: false,
              ),
            ),
          ),
          Builder(
            builder: (buttonContext) => ChatQuillColorStyleButton(
              controller: controller,
              type: ChatQuillColorStyleType.background,
              tooltip: 'toolbar_bg_color'.tr(),
              onPressed: () => notePickColorBubble(
                buttonContext,
                controller,
                focusNode,
                background: true,
              ),
            ),
          ),
          _buildDivider(context),
          if (onAiTap != null || noteId != null) _buildAiButton(context, iconColor),
          _buildSearchButton(context, iconColor),
          _buildDivider(context),
          _buildActionButton(
            HugeIcons.strokeRoundedLeftToRightListBullet,
            Attribute.ul,
            withShortcut('note_bullet_list'.tr(), shortcut('L', shift: true)),
            iconColor,
          ),
          _buildActionButton(
            HugeIcons.strokeRoundedLeftToRightListNumber,
            Attribute.ol,
            withShortcut('note_ordered_list'.tr(), shortcut('O', shift: true)),
            iconColor,
          ),
          _buildTaskListButton(context, iconColor),
          _buildActionButton(
            HugeIcons.strokeRoundedQuoteDown,
            Attribute.blockQuote,
            withShortcut('toolbar_quote'.tr(), shortcut('B', shift: true)),
            iconColor,
          ),
          _buildDivider(context),
          _buildLinkButton(context, iconColor),
          _buildCustomBtn(
            HugeIcons.strokeRoundedImage01,
            'note_image'.tr(),
            iconColor,
            () => noteInsertImage(context, ref, controller, focusNode),
          ),
          _buildDivider(context),
          _buildAlignButton(context, iconColor),
          _buildCustomBtn(
            HugeIcons.strokeRoundedSeparatorHorizontal,
            'note_horizontal_rule'.tr(),
            iconColor,
            () => noteInsertHorizontalRule(controller, focusNode),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    List<List<dynamic>> icon,
    Attribute attr,
    String tooltip,
    Color color,
  ) {
    return ChatQuillToggleStyleButton(
      controller: controller,
      focusNode: focusNode,
      icon: icon,
      attribute: attr,
      tooltip: tooltip,
      color: color,
    );
  }

  Widget _buildCustomBtn(
    List<List<dynamic>> icon,
    String tooltip,
    Color color,
    VoidCallback? action,
  ) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: action,
      icon: HugeIcon(icon: icon, size: 16, color: color),
    );
  }

  /// AI 助手按钮：气泡式快捷入口（参考标题/对齐气泡）
  /// 点击后在按钮下方弹出操作列表，选中后关闭气泡并打开 AI 面板（预选对应动作）
  Widget _buildAiButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (buttonContext) => IconButton(
        mouseCursor: SystemMouseCursors.click,
        tooltip: 'note_ai.title'.tr(),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          // 若外部仍提供 onAiTap（旧调用），优先走自定义回调以兼容
          // 否则走内置气泡快捷入口 + 预选动作打开面板
          if (onAiTap != null && noteId == null && onTitleSelected == null) {
            onAiTap!.call();
            return;
          }
          Function? close;
          close = showNoteBubble(
            buttonContext,
            maxWidth: 280,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedFileSearch,
                    label: 'note_ai.action_summarize'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'SUMMARIZE');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedBrush,
                    label: 'note_ai.action_polish'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'POLISH');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedExpand,
                    label: 'note_ai.action_expand'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'EXPAND');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedText,
                    label: 'note_ai.action_title'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'TITLE');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedTranslate,
                    label: 'note_ai.action_translate'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'TRANSLATE');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedPen01,
                    label: 'note_ai.action_continue'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'CONTINUE');
                    },
                  ),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedMagicWand01,
                    label: 'note_ai.action_custom'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, 'CUSTOM');
                    },
                  ),
                  const Divider(height: 1, thickness: .5),
                  _aiBubbleTile(
                    buttonContext,
                    icon: HugeIcons.strokeRoundedSparkles,
                    label: 'note_ai.title'.tr(),
                    onTap: () {
                      close?.call();
                      _openAiSheet(buttonContext, null);
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
      ),
    );
  }

  void _openAiSheet(BuildContext ctx, String? api) {
    final c = controller;
    // noteId 优先使用显式传入，其次尝试从 onAiTap 闭包外的上下文解析（兼容旧调用）
    showNoteAiSheet(
      ctx,
      controller: c,
      noteId: noteId,
      initialAction: api,
      onTitle: onTitleSelected,
    );
  }

  Widget _aiBubbleTile(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: cs.primary.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 15, color: cs.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface)),
            const Spacer(),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 13, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  /// 查找按钮：点击切换右侧查找面板
  Widget _buildSearchButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: withShortcut('note_search_in_doc'.tr(), shortcut('F')),
      visualDensity: VisualDensity.compact,
      onPressed: onSearchToggle,
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedSearch02,
        size: 16,
        color: searchActive ? colorScheme.primary : color,
        strokeWidth: searchActive ? 2.5 : 1.5,
      ),
    );
  }

  /// 任务列表按钮：当前处于任务列表时高亮。
  /// 点击为完整开关——未处于任务列表时插入复选框，
  /// 已处于任务列表时移除复选框（还原为普通段落），方便删掉误加的条目。
  Widget _buildTaskListButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final listValue = controller
            .getSelectionStyle()
            .attributes[Attribute.list.key]
            ?.value;
        final isChecked = listValue == Attribute.checked.value;
        final isUnchecked = listValue == Attribute.unchecked.value;
        final isSelected = isChecked || isUnchecked;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: withShortcut(
            'note_task_list'.tr(),
            shortcut('C', shift: true),
          ),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (isSelected) {
              // 再次点击移除复选框，还原为普通段落
              controller.formatSelection(
                Attribute.clone(Attribute.list, null),
              );
            } else {
              controller.formatSelection(Attribute.checked);
            }
            focusNode.requestFocus();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCheckList,
            size: 16,
            color: isSelected ? colorScheme.primary : color,
            strokeWidth: isSelected ? 2.5 : 1.5,
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
    );
  }

  /// 标题级别按钮（正文 / H1 / H2 / H3 / 代码块）
  Widget _buildHeaderButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final style = controller.getSelectionStyle();
        final headerValue = style.attributes[Attribute.header.key]?.value;
        final isCodeBlock = style.attributes.containsKey(
          Attribute.codeBlock.key,
        );

        final List<List<dynamic>> icon;
        final bool active;
        if (isCodeBlock) {
          icon = HugeIcons.strokeRoundedCode;
          active = true;
        } else {
          icon = switch (headerValue) {
            1 => HugeIcons.strokeRoundedHeading,
            2 => HugeIcons.strokeRoundedHeading01,
            3 => HugeIcons.strokeRoundedHeading02,
            _ => HugeIcons.strokeRoundedTextFont,
          };
          active = headerValue != null;
        }

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_header'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            // 气泡菜单：锚定按钮下方，点击外部自动关闭
            Function? close;
            close = showNoteBubble(
              context,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedTextFont,
                      label: 'note_header_normal'.tr(),
                      selected: !isCodeBlock && headerValue == null,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(
                          Attribute.clone(Attribute.header, null),
                        );
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedHeading,
                      label: 'note_header_h1'.tr(),
                      selected: !isCodeBlock && headerValue == 1,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h1);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedHeading01,
                      label: 'note_header_h2'.tr(),
                      selected: !isCodeBlock && headerValue == 2,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h2);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedHeading02,
                      label: 'note_header_h3'.tr(),
                      selected: !isCodeBlock && headerValue == 3,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h3);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedCode,
                      label: 'note_header_code'.tr(),
                      selected: isCodeBlock,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.codeBlock);
                        focusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: HugeIcon(
            icon: icon,
            size: 16,
            color: active ? colorScheme.primary : color,
            strokeWidth: active ? 2.5 : 1.5,
          ),
        );
      },
    );
  }

  /// 对齐方式按钮
  Widget _buildAlignButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final style = controller.getSelectionStyle();
        final alignValue = style.attributes[Attribute.align.key]?.value;
        final icon = switch (alignValue) {
          'center' => HugeIcons.strokeRoundedTextAlignCenter,
          'right' => HugeIcons.strokeRoundedTextAlignRight,
          'justify' => HugeIcons.strokeRoundedTextAlignJustifyCenter,
          _ => HugeIcons.strokeRoundedTextAlignLeft,
        };
        final active = alignValue != null;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_align'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            // 气泡菜单：锚定按钮下方，点击外部自动关闭
            Function? close;
            close = showNoteBubble(
              context,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedTextAlignLeft,
                      label: 'note_align_left'.tr(),
                      selected: alignValue == null || alignValue == 'left',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.leftAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedTextAlignCenter,
                      label: 'note_align_center'.tr(),
                      selected: alignValue == 'center',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.centerAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedTextAlignRight,
                      label: 'note_align_right'.tr(),
                      selected: alignValue == 'right',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.rightAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    _bubbleMenuTile(
                      context,
                      icon: HugeIcons.strokeRoundedTextAlignJustifyCenter,
                      label: 'note_align_justify'.tr(),
                      selected: alignValue == 'justify',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(
                          Attribute.justifyAlignment,
                        );
                        focusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: HugeIcon(
            icon: icon,
            size: 16,
            color: active ? colorScheme.primary : color,
            strokeWidth: active ? 2.5 : 1.5,
          ),
        );
      },
    );
  }

  /// 链接按钮：弹出输入框设置/移除链接
  Widget _buildLinkButton(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isLinked = controller.getSelectionStyle().attributes.containsKey(
          Attribute.link.key,
        );
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_link'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              noteSetLinkBubble(context, controller, focusNode),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedLink01,
            size: 16,
            color: isLinked ? colorScheme.primary : color,
            strokeWidth: isLinked ? 2.5 : 1.5,
          ),
        );
      },
    );
  }

  /// 气泡菜单项：图标 + 文案 + 选中勾选标记
  Widget _bubbleMenuTile(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: colorScheme.primary.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 15,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (selected)
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 14,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
