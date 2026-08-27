import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 树节点操作（右键 / 长按菜单项）
enum NoteTreeAction {
  newNote,
  newSubfolder,
  rename,
  move,
  pin,
  tags,
  share,
  delete,
}

/// 右键菜单条目描述
class NoteTreeMenuEntry {
  const NoteTreeMenuEntry(
    this.action,
    this.icon,
    this.label, {
    this.danger = false,
    this.separatorBefore = false,
    this.enabled = true,
  });

  final NoteTreeAction action;
  final List<List<dynamic>> icon;
  final String label;

  /// 危险操作（删除）：图标与文字使用错误色
  final bool danger;

  /// 在条目上方插入分组分隔线
  final bool separatorBefore;

  /// 是否可点击（false 时置灰且不可触发）
  final bool enabled;
}

/// 右键菜单项：图标底 + 文字，带 hover 高亮
class NoteTreeMenuItem extends PopupMenuEntry<NoteTreeAction> {
  const NoteTreeMenuItem({super.key, required this.entry});

  final NoteTreeMenuEntry entry;

  @override
  double get height => 34;

  @override
  bool represents(NoteTreeAction? value) => value == entry.action;

  @override
  State<PopupMenuEntry<NoteTreeAction>> createState() =>
      NoteTreeMenuItemState();
}

class NoteTreeMenuItemState extends State<NoteTreeMenuItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final enabled = entry.enabled;
    final accent = entry.danger ? colorScheme.error : colorScheme.primary;
    final labelColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: .35)
        : entry.danger
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: enabled
          ? () => Navigator.of(context).pop(entry.action)
          : null,
      borderRadius: BorderRadius.circular(8),
      hoverColor: colorScheme.primaryContainer.withValues(alpha: .35),
      highlightColor: accent.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled
                    ? accent.withValues(alpha: entry.danger ? .10 : .08)
                    : colorScheme.onSurface.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: entry.icon,
                size: 14,
                color: !enabled
                    ? colorScheme.onSurface.withValues(alpha: .25)
                    : entry.danger
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右键菜单顶部标题（显示文件夹 / 笔记名）
class NoteTreeMenuHeaderEntry extends PopupMenuEntry<NoteTreeAction> {
  const NoteTreeMenuHeaderEntry({super.key, required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  double get height => 34;

  @override
  bool represents(NoteTreeAction? value) => false;

  @override
  State<PopupMenuEntry<NoteTreeAction>> createState() =>
      NoteTreeMenuHeaderEntryState();
}

class NoteTreeMenuHeaderEntryState extends State<NoteTreeMenuHeaderEntry> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
      color: colorScheme.primary.withValues(alpha: .05),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: HugeIcon(
              icon: widget.icon,
              size: 12,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
