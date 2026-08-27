import 'package:anoxia/common/utils/shortcut_hint.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_quill_actions.dart';
import 'note_toolbar_groups_a.dart';
import 'note_toolbar_groups_b.dart';

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

  /// AI 助手按钮点击回调（为空则不显示按钮，兼容旧版气泡入口）
  final VoidCallback? onAiTap;

  /// 当前笔记ID（用于 AI 请求在 content 为空时按 noteId 读取，气泡模式下使用）
  final int? noteId;

  /// 标题回填回调（TITLE 动作生成标题时使用，气泡模式）
  final ValueChanged<String>? onTitleSelected;

  /// AI 面板是否展开（高亮用）
  final bool aiActive;

  /// AI 面板切换回调（新的右侧面板互斥模式）
  final VoidCallback? onAiToggle;

  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchActive,
    required this.onSearchToggle,
    this.onAiTap,
    this.noteId,
    this.onTitleSelected,
    this.aiActive = false,
    this.onAiToggle,
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
          const NoteToolbarDivider(),
          NoteToolbarHeaderButton(
            controller: controller,
            focusNode: focusNode,
            iconColor: iconColor,
          ),
          const NoteToolbarDivider(),
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
          const NoteToolbarDivider(),
          // 颜色面板以气泡方式弹出，锚定按钮下方（仿聊天输入框）
          NoteToolbarColorGroup(
            controller: controller,
            focusNode: focusNode,
          ),
          const NoteToolbarDivider(),
          // AI 与搜索互斥：受服务端 noteEnabled 控制，关闭时隐藏
          Builder(
            builder: (context) {
              final noteEnabled = ref.watch(aiFeatureFlagsProvider).value?.noteEnabled ?? true;
              if (!noteEnabled) return const SizedBox.shrink();
              if (onAiToggle != null || onAiTap != null || noteId != null) {
                return NoteToolbarAiButton(
                  controller: controller,
                  iconColor: iconColor,
                  noteId: noteId,
                  onAiTap: onAiTap,
                  onTitleSelected: onTitleSelected,
                  onAiToggle: onAiToggle,
                  aiActive: aiActive,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          NoteToolbarSearchButton(
            searchActive: searchActive,
            onSearchToggle: onSearchToggle,
            iconColor: iconColor,
          ),
          const NoteToolbarDivider(),
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
          const NoteToolbarDivider(),
          NoteToolbarLinkButton(
            controller: controller,
            focusNode: focusNode,
            iconColor: iconColor,
          ),
          NoteToolbarCustomButton(
            icon: HugeIcons.strokeRoundedImage01,
            tooltip: 'note_image'.tr(),
            color: iconColor,
            onPressed: () => noteInsertImage(context, ref, controller, focusNode),
          ),
          const NoteToolbarDivider(),
          NoteToolbarAlignButton(
            controller: controller,
            focusNode: focusNode,
            iconColor: iconColor,
          ),
          NoteToolbarCustomButton(
            icon: HugeIcons.strokeRoundedSeparatorHorizontal,
            tooltip: 'note_horizontal_rule'.tr(),
            color: iconColor,
            onPressed: () => noteInsertHorizontalRule(controller, focusNode),
          ),
        ],
      ),
    );
  }
}
