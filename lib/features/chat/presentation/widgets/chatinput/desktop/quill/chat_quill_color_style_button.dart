import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

enum ChatQuillColorStyleType { foreground, background }

/// 显示当前 Quill 文字颜色或背景颜色的工具栏按钮。
class ChatQuillColorStyleButton extends StatelessWidget {
  const ChatQuillColorStyleButton({
    super.key,
    required this.controller,
    required this.type,
    required this.tooltip,
    required this.onPressed,
  });

  final QuillController controller;
  final ChatQuillColorStyleType type;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final selectedColor = _selectedColor();
        final isSelected = selectedColor != null;
        final isBackground = type == ChatQuillColorStyleType.background;
        final iconColor = selectedColor ?? colorScheme.onSurfaceVariant;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          isSelected: isSelected,
          style: IconButton.styleFrom(
            foregroundColor: iconColor,
          ),
          onPressed: onPressed,
          icon: HugeIcon(
            icon: isBackground
                ? HugeIcons.strokeRoundedBackground
                : HugeIcons.strokeRoundedTextColor,
            size: 14,
            color: iconColor,
            strokeWidth: isSelected ? 2.5 : 1.5,
          ),
        );
      },
    );
  }

  Color? _selectedColor() {
    final attributeKey = type == ChatQuillColorStyleType.background
        ? Attribute.background.key
        : Attribute.color.key;
    final value = controller
        .getSelectionStyle()
        .attributes[attributeKey]
        ?.value;
    if (value is! String || !value.startsWith('#')) return null;

    var hex = value.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final argb = int.tryParse(hex, radix: 16);
    return argb == null ? null : Color(argb);
  }
}
