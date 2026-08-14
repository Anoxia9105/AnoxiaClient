import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

/// Quill 格式切换按钮。
///
/// 监听控制器的选区与待输入样式，使按钮状态与光标位置保持同步；点击后
/// 将焦点交还编辑器，因此折叠光标处设置的格式可以直接应用到后续输入。
class ChatQuillToggleStyleButton extends StatelessWidget {
  const ChatQuillToggleStyleButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.attribute,
    required this.tooltip,
    this.color,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final List<List<dynamic>> icon;
  final Attribute attribute;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final isSelected = controller
            .getSelectionStyle()
            .attributes
            .containsKey(attribute.key);
        final iconColor = isSelected
            ? colorScheme.primary
            : color ?? colorScheme.onSurfaceVariant;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          isSelected: isSelected,
          style: IconButton.styleFrom(
            foregroundColor: iconColor,
            backgroundColor: isSelected ? colorScheme.primaryContainer : null,
          ),
          onPressed: () {
            controller.formatSelection(
              isSelected ? Attribute.clone(attribute, null) : attribute,
            );
            focusNode.requestFocus();
          },
          icon: HugeIcon(
            icon: icon,
            size: 16,
            color: iconColor,
            strokeWidth: isSelected ? 2.5 : 1.5,
          ),
        );
      },
    );
  }
}
