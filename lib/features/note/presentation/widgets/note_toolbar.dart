import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_quill_actions.dart';

/// 记事本富文本工具栏
///
/// 双行布局（窄窗口下可横向滚动）：
/// - 第一行：撤销 / 重做 / 清除格式 / 标题级别 / 粗斜下划线删除线 / 行内代码 / 文字颜色 / 背景色
/// - 第二行：无序列表 / 有序列表 / 任务列表 / 引用 / 链接 / 图片 / 对齐
class NoteToolbar extends ConsumerWidget {
  final QuillController controller;
  final FocusNode focusNode;

  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCustomBtn(
                  HugeIcons.strokeRoundedUndo,
                  'note_undo'.tr(),
                  iconColor,
                  controller.undo,
                ),
                _buildCustomBtn(
                  HugeIcons.strokeRoundedRedo,
                  'note_redo'.tr(),
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
                  'toolbar_bold'.tr(),
                  iconColor,
                ),
                _buildActionButton(
                  HugeIcons.strokeRoundedTextItalic,
                  Attribute.italic,
                  'toolbar_italic'.tr(),
                  iconColor,
                ),
                _buildActionButton(
                  HugeIcons.strokeRoundedTextUnderline,
                  Attribute.underline,
                  'toolbar_underline'.tr(),
                  iconColor,
                ),
                _buildActionButton(
                  HugeIcons.strokeRoundedTextStrikethrough,
                  Attribute.strikeThrough,
                  'toolbar_strikethrough'.tr(),
                  iconColor,
                ),
                _buildActionButton(
                  HugeIcons.strokeRoundedSourceCode,
                  Attribute.inlineCode,
                  'toolbar_inline_code'.tr(),
                  iconColor,
                ),
                _buildDivider(context),
                ChatQuillColorStyleButton(
                  controller: controller,
                  type: ChatQuillColorStyleType.foreground,
                  tooltip: 'toolbar_text_color'.tr(),
                  onPressed: () => notePickColor(
                    context,
                    controller,
                    focusNode,
                    background: false,
                  ),
                ),
                ChatQuillColorStyleButton(
                  controller: controller,
                  type: ChatQuillColorStyleType.background,
                  tooltip: 'toolbar_bg_color'.tr(),
                  onPressed: () => notePickColor(
                    context,
                    controller,
                    focusNode,
                    background: true,
                  ),
                ),
                _buildDivider(context),
                _buildCustomBtn(
                  HugeIcons.strokeRoundedSearch02,
                  'note_search_in_doc'.tr(),
                  iconColor,
                  () => showDialog<void>(
                    context: context,
                    builder: (_) => QuillToolbarSearchDialog(
                      controller: controller,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(
                  HugeIcons.strokeRoundedLeftToRightListBullet,
                  Attribute.ul,
                  'note_bullet_list'.tr(),
                  iconColor,
                ),
                _buildActionButton(
                  HugeIcons.strokeRoundedLeftToRightListNumber,
                  Attribute.ol,
                  'note_ordered_list'.tr(),
                  iconColor,
                ),
                _buildTaskListButton(context, iconColor),
                _buildActionButton(
                  HugeIcons.strokeRoundedQuoteDown,
                  Attribute.blockQuote,
                  'toolbar_quote'.tr(),
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
              ],
            ),
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

  /// 任务列表按钮：仅当当前列表为待办/完成态时高亮，点击在两种状态间切换。
  Widget _buildTaskListButton(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final listValue =
            controller.getSelectionStyle().attributes[Attribute.list.key]?.value;
        final isChecked = listValue == Attribute.checked.value;
        final isUnchecked = listValue == Attribute.unchecked.value;
        final isSelected = isChecked || isUnchecked;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_task_list'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: isSelected,
          style: IconButton.styleFrom(
            foregroundColor:
                isSelected ? Theme.of(context).colorScheme.primary : color,
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
          onPressed: () {
            if (isChecked) {
              controller.formatSelection(Attribute.unchecked);
            } else {
              controller.formatSelection(Attribute.checked);
            }
            focusNode.requestFocus();
          },
          icon: Icon(
            Icons.checklist,
            size: 18,
            color: isSelected ? Theme.of(context).colorScheme.primary : color,
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final style = controller.getSelectionStyle();
        final headerValue = style.attributes[Attribute.header.key]?.value;
        final isCodeBlock =
            style.attributes.containsKey(Attribute.codeBlock.key);

        final IconData icon;
        final bool active;
        if (isCodeBlock) {
          icon = Icons.code;
          active = true;
        } else {
          icon = switch (headerValue) {
            1 => Icons.title,
            2 => Icons.title,
            3 => Icons.title,
            _ => Icons.text_fields,
          };
          active = headerValue != null;
        }

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_header'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: active,
          style: IconButton.styleFrom(
            foregroundColor: active ? Theme.of(context).colorScheme.primary : color,
            backgroundColor: active
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final offset = box.localToGlobal(Offset.zero);

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + box.size.height + 4,
                offset.dx + box.size.width,
                offset.dy + box.size.height + 4 + 260,
              ),
              items: [
                _stringMenuItem('normal', 'note_header_normal', Icons.text_fields),
                _stringMenuItem('h1', 'note_header_h1', Icons.title),
                _stringMenuItem('h2', 'note_header_h2', Icons.title),
                _stringMenuItem('h3', 'note_header_h3', Icons.title),
                _stringMenuItem('code', 'note_header_code', Icons.code),
              ],
            ).then((value) {
              if (!context.mounted || value == null) return;
              switch (value) {
                case 'normal':
                  controller.formatSelection(
                    Attribute.clone(Attribute.header, null),
                  );
                case 'h1':
                  controller.formatSelection(Attribute.h1);
                case 'h2':
                  controller.formatSelection(Attribute.h2);
                case 'h3':
                  controller.formatSelection(Attribute.h3);
                case 'code':
                  controller.formatSelection(Attribute.codeBlock);
              }
              focusNode.requestFocus();
            });
          },
          icon: Icon(icon, size: 16),
        );
      },
    );
  }

  /// 对齐方式按钮
  Widget _buildAlignButton(BuildContext context, Color color) {
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
          isSelected: active,
          style: IconButton.styleFrom(
            foregroundColor: active ? Theme.of(context).colorScheme.primary : color,
          ),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final offset = box.localToGlobal(Offset.zero);

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + box.size.height + 4,
                offset.dx + box.size.width,
                offset.dy + box.size.height + 4 + 220,
              ),
              items: [
                _stringMenuItem('left', 'note_align_left', Icons.format_align_left),
                _stringMenuItem('center', 'note_align_center', Icons.format_align_center),
                _stringMenuItem('right', 'note_align_right', Icons.format_align_right),
                _stringMenuItem('justify', 'note_align_justify', Icons.format_align_justify),
              ],
            ).then((value) {
              if (!context.mounted || value == null) return;
              controller.formatSelection(
                switch (value) {
                  'center' => Attribute.centerAlignment,
                  'right' => Attribute.rightAlignment,
                  'justify' => Attribute.justifyAlignment,
                  _ => Attribute.leftAlignment,
                },
              );
              focusNode.requestFocus();
            });
          },
          icon: HugeIcon(icon: icon, size: 16),
        );
      },
    );
  }

  /// 链接按钮：弹出输入框设置/移除链接
  Widget _buildLinkButton(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isLinked = controller
            .getSelectionStyle()
            .attributes
            .containsKey(Attribute.link.key);
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_link'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: isLinked,
          style: IconButton.styleFrom(
            foregroundColor:
                isLinked ? Theme.of(context).colorScheme.primary : color,
          ),
          onPressed: () => noteSetLink(context, controller, focusNode),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 16),
        );
      },
    );
  }

  PopupMenuItem<String> _stringMenuItem(
    String value,
    String labelKey,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(labelKey.tr()),
        ],
      ),
    );
  }
}