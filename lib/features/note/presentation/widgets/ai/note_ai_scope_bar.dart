/// 记事本 AI「作用范围」分段控件（手机端弹框 / 桌面端侧栏共用）
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/theme/radius_token.dart';

import 'note_ai_field_label.dart';

/// 作用范围分段控件。
///
/// 把原先只挂在标题栏的一句小号「仅处理选中文字」，升级成两段互斥控件，
/// 让「AI 这一次读的是哪部分内容」在视觉上一眼可见、且随时可切。
///
/// - [whole] `true` = 整篇笔记，`false` = 仅选中文字
/// - [selectionChars] 为 0（无选区）时，「选中文字」段置灰且不可点
/// - [totalChars] 整篇字数，直接展示让「要发多少 token」有预期
class NoteAiScopeBar extends StatelessWidget {
  const NoteAiScopeBar({
    super.key,
    required this.whole,
    required this.selectionChars,
    required this.totalChars,
    required this.onChanged,
  });

  final bool whole;
  final int selectionChars;
  final int totalChars;

  /// 切换回调：`true` 表示切到整篇笔记
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSelection = selectionChars > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteAiFieldLabel('note_ai.scope'.tr()),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ScopeOption(
                  icon: HugeIcons.strokeRoundedCursorText,
                  label: 'note_ai.scope_selection'.tr(),
                  count: selectionChars,
                  selected: !whole,
                  enabled: hasSelection,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ScopeOption(
                  icon: HugeIcons.strokeRoundedNote,
                  label: 'note_ai.scope_all'.tr(),
                  count: totalChars,
                  selected: whole,
                  enabled: true,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单段：图标 + 名称 + 字数
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 选中态用主色渐变底 + 主色描边环；未选中保持中性，悬停才浮起
    final selectedBg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        cs.primary.withValues(alpha: .26),
        cs.primary.withValues(alpha: .14),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(RadiusToken.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              gradient: selected ? selectedBg : null,
              borderRadius: BorderRadius.circular(RadiusToken.md),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: .42)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: icon,
                  size: 14,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 11.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (selected ? cs.onSurface : cs.onSurfaceVariant)
                            .withValues(alpha: .72),
                        fontFeatures: const [FontFeature.tabularFigures()],
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
