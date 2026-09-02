import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_quill_actions.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 记事本工具栏分组组件 - 基础部件
///
/// 包含分隔线、通用按钮、气泡菜单及标题/对齐等基础控制。

/// 分隔线
class NoteToolbarDivider extends StatelessWidget {
  const NoteToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
    );
  }
}

/// 自定义按钮（非切换态）
class NoteToolbarCustomButton extends StatelessWidget {
  const NoteToolbarCustomButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: HugeIcon(icon: icon, size: 16, color: color),
    );
  }
}

/// 切换态按钮（基于 Quill 属性）
class NoteToolbarToggleButton extends StatelessWidget {
  const NoteToolbarToggleButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.attribute,
    required this.tooltip,
    required this.color,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final List<List<dynamic>> icon;
  final Attribute attribute;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ChatQuillToggleStyleButton(
      controller: controller,
      focusNode: focusNode,
      icon: icon,
      attribute: attribute,
      tooltip: tooltip,
      color: color,
    );
  }
}

/// 气泡菜单项：图标 + 文案 + 选中勾选标记
class NoteToolbarBubbleMenuTile extends StatelessWidget {
  const NoteToolbarBubbleMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.md),
      hoverColor: colorScheme.primary.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 15,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
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

/// AI 气泡菜单项
class NoteToolbarAiBubbleTile extends StatelessWidget {
  const NoteToolbarAiBubbleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.md),
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
}

/// 标题级别按钮（正文 / H1 / H2 / H3 / 代码块）
class NoteToolbarHeaderButton extends StatelessWidget {
  const NoteToolbarHeaderButton({
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
        final style = controller.getSelectionStyle();
        final headerValue = style.attributes[Attribute.header.key]?.value;
        final isCodeBlock = style.attributes.containsKey(Attribute.codeBlock.key);

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
          key: btnKey,
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_header'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            // 气泡菜单：锚定按钮下方，点击外部自动关闭
            Function? close;
            close = showNoteBubble(
              context,
              anchorKey: btnKey,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedTextFont,
                      label: 'note_header_normal'.tr(),
                      selected: !isCodeBlock && headerValue == null,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.clone(Attribute.header, null));
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedHeading,
                      label: 'note_header_h1'.tr(),
                      selected: !isCodeBlock && headerValue == 1,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h1);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedHeading01,
                      label: 'note_header_h2'.tr(),
                      selected: !isCodeBlock && headerValue == 2,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h2);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedHeading02,
                      label: 'note_header_h3'.tr(),
                      selected: !isCodeBlock && headerValue == 3,
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.h3);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
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
            color: active ? colorScheme.primary : iconColor,
            strokeWidth: active ? 2.5 : 1.5,
          ),
        );
      },
    );
  }
}

/// 对齐方式按钮
class NoteToolbarAlignButton extends StatelessWidget {
  const NoteToolbarAlignButton({
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
          key: btnKey,
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_align'.tr(),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            // 气泡菜单：锚定按钮下方，点击外部自动关闭
            Function? close;
            close = showNoteBubble(
              context,
              anchorKey: btnKey,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedTextAlignLeft,
                      label: 'note_align_left'.tr(),
                      selected: alignValue == null || alignValue == 'left',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.leftAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedTextAlignCenter,
                      label: 'note_align_center'.tr(),
                      selected: alignValue == 'center',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.centerAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedTextAlignRight,
                      label: 'note_align_right'.tr(),
                      selected: alignValue == 'right',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.rightAlignment);
                        focusNode.requestFocus();
                      },
                    ),
                    NoteToolbarBubbleMenuTile(
                      icon: HugeIcons.strokeRoundedTextAlignJustifyCenter,
                      label: 'note_align_justify'.tr(),
                      selected: alignValue == 'justify',
                      onTap: () {
                        close?.call();
                        controller.formatSelection(Attribute.justifyAlignment);
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
            color: active ? colorScheme.primary : iconColor,
            strokeWidth: active ? 2.5 : 1.5,
          ),
        );
      },
    );
  }
}
