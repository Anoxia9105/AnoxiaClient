import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 构建分裂按钮（左侧功能按钮 + 右侧下拉箭头）
///
/// 用于需要设备选择功能的控制按钮，如麦克风、摄像头、扬声器
Widget buildSplitButton({
  required VoidCallback onTap,
  required VoidCallback onArrowTap,
  required List<List<dynamic>> icon,
  required String label,
  required BuildContext context,
  bool active = false,
}) {
  final color = active ? Theme.of(context).colorScheme.primary : null;
  final dividerColor = Theme.of(
    context,
  ).colorScheme.onSurface.withValues(alpha: 0.15);

  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: dividerColor, width: 0.5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: label,
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: HugeIcon(icon: icon, size: 18, color: color),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 0.5, color: dividerColor),
            SizedBox(
              height: double.infinity,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                onTap: onArrowTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 构建单体按钮（无下拉菜单）
///
/// 用于简单的开关功能，如举手、表情、屏幕共享
Widget buildSoloButton({
  required VoidCallback onTap,
  required List<List<dynamic>> icon,
  required String label,
  required BuildContext context,
  bool active = false,
}) {
  final color = active ? Theme.of(context).colorScheme.primary : null;

  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.15),
        width: 0.5,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: label,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: HugeIcon(icon: icon, size: 18, color: color),
          ),
        ),
      ),
    ),
  );
}

/// 显示表情选择器
void showReactionPicker(
  BuildContext context,
  void Function(String emoji) onReaction,
) {
  const emojis = ['👍', '❤️', '😂', '😮', '👏', '🎉', '🔥', '💯'];

  Function? close;
  close = Toast.showWidget(
    context,
    direction: PreferDirection.topRight,
    child: Material(
      color: Colors.transparent,
      child: BubbleWidget(
        arrowDirection: AxisDirection.up,
        arrowOffset: 410,
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        contentBuilder: (context) => Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: emojis.map((emoji) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  onReaction(emoji);
                  close?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}