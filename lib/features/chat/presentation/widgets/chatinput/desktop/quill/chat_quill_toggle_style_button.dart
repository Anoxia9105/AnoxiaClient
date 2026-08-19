import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

/// Quill 格式切换按钮。
///
/// 监听控制器的选区与待输入样式，使按钮状态与光标位置保持同步；点击后
/// 将焦点交还编辑器，因此折叠光标处设置的格式可以直接应用到后续输入。
///
/// 选中态：图标加粗（增大 strokeWidth）并以主题色高亮，不叠加背景色。
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

  /// 判断当前选区是否命中该样式。
  ///
  /// 有序/无序/任务列表共用 `list` 键，必须比较 value 而不是只看键是否存在，
  /// 否则「点击无序列表会有序列表也高亮、点击任务列表三个全部高亮」。
  bool _isSelected(Style style) {
    final attr = attribute;
    if (attr.key == Attribute.list.key) {
      return style.attributes[attr.key]?.value == attr.value;
    }
    return style.attributes.containsKey(attr.key);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final isSelected = _isSelected(controller.getSelectionStyle());
        final iconColor = isSelected
            ? colorScheme.primary
            : color ?? colorScheme.onSurfaceVariant;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          isSelected: isSelected,
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