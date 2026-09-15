/// 记事本 AI「能力」网格（手机端弹框 / 桌面端侧栏共用）
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

import '../note_ai_action.dart';
import '../note_ai_langs.dart';
import 'note_ai_field_label.dart';

/// 把 7 项能力排成 4 列图标网格，一屏看全。
///
/// 相比原先 `Wrap` + `ChoiceChip` 的两行大胶囊：
/// - 图标放进 32px 圆角方块里，选中时方块转主色渐变并带同色投影，
///   视觉重心明确，不再是一排等重的灰胶囊；
/// - 生成中不再静默禁用，而是整体降透明度 + 降饱和，保留位置感；
/// - 「自定义」与「翻译」的附加输入就地展开在网格下方，不跳行。
class NoteAiCapabilityGrid extends StatelessWidget {
  const NoteAiCapabilityGrid({
    super.key,
    required this.action,
    required this.enabled,
    required this.onSelected,
    required this.instructionCtrl,
    required this.targetLang,
    required this.onLangChanged,
  });

  /// 当前选中能力，null 表示尚未选择
  final NoteAiAction? action;

  /// 生成中传 false：整体置灰且不可点
  final bool enabled;

  final ValueChanged<NoteAiAction> onSelected;

  /// CUSTOM 能力的自定义指令输入
  final TextEditingController instructionCtrl;

  /// TRANSLATE 能力的目标语言
  final String targetLang;
  final ValueChanged<String?> onLangChanged;

  /// 每行列数（弹框与侧栏宽度接近，统一 4 列）
  static const int _columns = 4;

  /// 半饱和矩阵：禁用态用，比单纯降透明度更能表达「不可用」
  static const ColorFilter _desaturate = ColorFilter.matrix(<double>[
    0.6063, 0.3576, 0.0361, 0, 0, //
    0.1063, 0.8576, 0.0361, 0, 0, //
    0.1063, 0.3576, 0.5361, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = NoteAiAction.values;
    final rows = <List<NoteAiAction?>>[];
    for (var i = 0; i < values.length; i += _columns) {
      // 转成可空元素列表，末行不足 4 格时用 null 占位补齐，保证列宽一致
      final chunk = <NoteAiAction?>[
        ...values.sublist(
          i,
          (i + _columns) > values.length ? values.length : (i + _columns),
        ),
      ];
      while (chunk.length < _columns) {
        chunk.add(null);
      }
      rows.add(chunk);
    }

    final grid = Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: SpacingToken.sm),
          Row(
            children: [
              for (var c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const SizedBox(width: SpacingToken.sm),
                Expanded(
                  child: rows[r][c] == null
                      ? const SizedBox.shrink()
                      : _CapabilityTile(
                          action: rows[r][c]!,
                          selected: action == rows[r][c],
                          enabled: enabled,
                          onTap: () => onSelected(rows[r][c]!),
                        ),
                ),
              ],
            ],
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteAiFieldLabel('note_ai_capabilities'.tr()),
        // 生成中：降透明度 + 降饱和，保留位置感但不喧宾夺主
        if (enabled)
          grid
        else
          ColorFiltered(colorFilter: _desaturate, child: grid),
        _buildSubField(context, cs),
      ],
    );
  }

  /// 「自定义」「翻译」的附加输入，就地展开在网格下方
  Widget _buildSubField(BuildContext context, ColorScheme cs) {
    final Widget child;
    if (action == NoteAiAction.custom) {
      child = _SubField(
        key: const ValueKey('custom_field'),
        label: 'note_ai.action_custom'.tr(),
        child: TextField(
          controller: instructionCtrl,
          enabled: enabled,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'note_ai.instruction_hint'.tr(),
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: .7),
                ),
          ),
        ),
      );
    } else if (action == NoteAiAction.translate) {
      child = _SubField(
        key: ValueKey('lang_field_$targetLang'),
        label: 'note_ai.target_lang'.tr(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: targetLang,
            isDense: true,
            isExpanded: true,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            items: [
              for (final lang in noteTranslateLangs)
                DropdownMenuItem(
                  value: lang,
                  child: Text(lang, style: const TextStyle(fontSize: 12.5)),
                ),
            ],
            onChanged: enabled ? onLangChanged : null,
          ),
        ),
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('no_sub_field'));
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

/// 内联子字段容器：与网格之间留 10 的白，视觉上挂在网格下方
class _SubField extends StatelessWidget {
  const _SubField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: cs.outline,
                    letterSpacing: .4,
                  ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

/// 单个能力格：图标方块 + 名称
class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.action,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final NoteAiAction action;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : (selected ? .62 : .38),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(3, 11, 3, 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.primary.withValues(alpha: .15),
                        cs.primary.withValues(alpha: .05),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: .40)
                    : Colors.transparent,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primaryContainer.withValues(alpha: .26),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [cs.primary, cs.primaryContainer],
                          )
                        : null,
                    color: selected ? null : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(RadiusToken.md),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: cs.primaryContainer.withValues(alpha: .46),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: action.icon,
                      size: 17,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            selected ? cs.onSurface : cs.onSurfaceVariant,
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
