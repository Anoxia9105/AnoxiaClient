import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 拖拽负载：标识来源类型与所在容器
///
/// [containerId] 为当前条目所在父级文件夹 ID，null 表示根级。
class NoteDragItem {
  const NoteDragItem({
    required this.isFolder,
    required this.id,
    required this.containerId,
  });

  /// true=文件夹，false=笔记
  final bool isFolder;

  /// 条目 ID
  final int id;

  /// 所在容器（父文件夹 ID），null=根级
  final int? containerId;
}

/// 树行拖拽包装：桌面端支持「拖到行间=排序、拖到文件夹=移动」
///
/// 仅桌面端启用（移动端沿用「移动到」对话框）。行本身既可被拖出，
/// 也作为拖拽目标接收其它条目。
class NoteDraggableRow extends StatelessWidget {
  const NoteDraggableRow({
    super.key,
    required this.item,
    required this.feedbackLabel,
    required this.child,
    required this.canAccept,
    required this.onDrop,
  });

  /// 本行对应的拖拽负载
  final NoteDragItem item;

  /// 拖拽跟随卡片显示的标题
  final String feedbackLabel;

  /// 行内容
  final Widget child;

  /// 判断拖入本行的负载是否有效（返回 false 则不高亮、不触发 onDrop）
  final bool Function(NoteDragItem dragged) canAccept;

  /// 拖入本行时触发
  final ValueChanged<NoteDragItem> onDrop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<NoteDragItem>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: hovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                  color: colorScheme.primaryContainer.withValues(alpha: .55),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: .55)),
                )
              : null,
          child: Draggable<NoteDragItem>(
            data: item,
            feedback: _DragFeedback(label: feedbackLabel),
            childWhenDragging: Opacity(opacity: .35, child: child),
            child: child,
          ),
        );
      },
    );
  }
}

/// 拖拽跟随卡片
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 4,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedFile02,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith( fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}