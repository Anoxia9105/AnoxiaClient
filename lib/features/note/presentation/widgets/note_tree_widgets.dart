import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 文件夹行
class NoteTreeFolderRow extends StatelessWidget {
  final NoteFolderNode folder;
  final bool expanded;
  final VoidCallback onTap;

  /// 所在层级深度（根级为 0），用于缩进
  final int depth;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const NoteTreeFolderRow({
    super.key,
    required this.folder,
    required this.expanded,
    required this.onTap,
    required this.onMenuPosition,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onSecondaryTapDown: (details) => onMenuPosition(details.globalPosition),
      onLongPressStart: (details) => onMenuPosition(details.globalPosition),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8 + depth * 18, 8, 8, 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: expanded
                      ? HugeIcons.strokeRoundedFolderOpen
                      : HugeIcons.strokeRoundedFolder01,
                  size: 17,
                  color: colorScheme.primary.withValues(alpha: .85),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (folder.totalNoteCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(RadiusToken.pill),
                    ),
                    child: Text(
                      folder.totalNoteCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 笔记行
class NoteTreeRow extends StatelessWidget {
  final NoteBrief note;
  final bool selected;
  final int indent;

  /// 搜索高亮关键字（命中子串以高亮色渲染）
  final String? highlight;
  final VoidCallback onTap;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const NoteTreeRow({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
    required this.onMenuPosition,
    this.indent = 0,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = highlight?.trim() ?? '';

    return GestureDetector(
      onSecondaryTapDown: (details) => onMenuPosition(details.globalPosition),
      onLongPressStart: (details) => onMenuPosition(details.globalPosition),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: .35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8 + indent * 18, 8, 8, 8),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFile02,
                  size: 15,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: .7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.pinned) ...[
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedPin02,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: _buildHighlighted(
                              note.title.isEmpty
                                  ? 'note_untitled'.tr()
                                  : note.title,
                              query,
                              TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (note.preview.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _buildHighlighted(
                          note.preview.trim(),
                          query,
                          Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          colorScheme.primary,
                        ),
                      ],
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildTagChips(colorScheme),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标签小胶囊（最多展示 3 个，超出折叠为 +N）
  Widget _buildTagChips(ColorScheme colorScheme) {
    final tags = note.tags;
    final shown = tags.length > 3 ? tags.sublist(0, 3) : tags;
    final overflow = tags.length - shown.length;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final name in shown)
          NoteTreeTagChip(label: name, selected: false, dense: true, onTap: null),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
            child: Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// 命中关键字高亮渲染（大小写不敏感）
  Widget _buildHighlighted(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: _highlightSpans(text, query, style, highlightColor),
      ),
    );
  }

  List<TextSpan> _highlightSpans(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w700,
            backgroundColor: highlightColor.withValues(alpha: .18),
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }
}

/// 树列表加载骨架屏（替代转圈动画）
class NoteTreeListSkeleton extends StatelessWidget {
  const NoteTreeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        // 偶数行模拟文件夹，奇数行模拟笔记，贴近真实树结构
        final folder = index.isEven;
        return Row(
          children: [
            SkeletonBox(width: folder ? 16 : 15, height: 15, radius: 5),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(
                    width: folder ? 110 : 150,
                    height: 11,
                    radius: 6,
                  ),
                  if (!folder) ...[
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 90, height: 9, radius: 5),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 标签胶囊（过滤栏 / 笔记行内标签）
class NoteTreeTagChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// 紧凑模式（笔记行内标签，不可点击）
  final bool dense;
  final VoidCallback? onTap;

  const NoteTreeTagChip({
    super.key,
    required this.label,
    required this.selected,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.pill),
        onTap: onTap,
        child: Container(
          height: dense ? 18 : 24,
          padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 10 : 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
