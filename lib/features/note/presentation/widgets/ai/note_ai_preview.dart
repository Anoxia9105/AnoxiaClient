/// 记事本 AI 预览区（手机端弹框 / 桌面端侧栏共用）
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

import '../note_ai_action.dart';

/// 结果预览区：整个面板的弹性主区。
///
/// 相比原先 `minHeight 140 / maxHeight 300` 的固定小框，这里改为跟随容器
/// 伸缩 —— 结果多长就能读多长，不再出现「框内滚小窗口」的局促感。
///
/// 三种形态：
/// - 空态：给出 3 个快捷能力入口，缩短首次使用的决策路径；
/// - 生成中：骨架屏 + 主色描边呼吸，思考文本降级为脚注；
/// - 完成：Markdown 渲染 + 字数/复制，并标注「未写入正文」降低误操作焦虑。
class NoteAiPreview extends StatelessWidget {
  const NoteAiPreview({
    super.key,
    required this.text,
    required this.streaming,
    required this.thinking,
    required this.onCopy,
    this.onQuickPick,
  });

  /// 流式累计文本；空串代表还没有结果
  final String text;
  final bool streaming;

  /// 推理期思考文本（增量），null 表示无
  final String? thinking;

  final VoidCallback onCopy;

  /// 空态快捷入口：点击直接选中对应能力
  final ValueChanged<NoteAiAction>? onQuickPick;

  /// 空态建议的三项能力
  static const List<NoteAiAction> _suggestions = [
    NoteAiAction.summarize,
    NoteAiAction.polish,
    NoteAiAction.title,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final empty = text.isEmpty;
    final done = !empty && !streaming;
    final live = streaming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- 头部：预览标签 + 字数 + 复制 ----------
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                  border: Border.all(color: cs.primary.withValues(alpha: .25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedEye,
                      size: 12,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ai_preview_label'.tr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: cs.primary,
                          ),
                    ),
                  ],
                ),
              ),
              if (done) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(RadiusToken.sm),
                  ),
                  child: Text(
                    'note_ai_word_count'.tr(args: [text.length.toString()]),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onTertiaryContainer,
                        ),
                  ),
                ),
              ],
              const Spacer(),
              if (done)
                _IconSquareButton(
                  icon: HugeIcons.strokeRoundedCopy01,
                  tooltip: 'note_ai.copy'.tr(),
                  onTap: onCopy,
                ),
            ],
          ),
        ),

        // ---------- 主体 ----------
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _surfaceColor(cs, done: done),
              borderRadius: BorderRadius.circular(RadiusToken.xl),
              border: Border.all(
                color: done
                    ? cs.primary.withValues(alpha: .20)
                    : live
                        ? cs.primary.withValues(alpha: .34)
                        : cs.outlineVariant.withValues(alpha: .40),
              ),
            ),
            child: Stack(
              children: [
                // 顶部一条淡化高光线，做出「玻璃面板」质感
                Positioned(
                  top: 0,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          cs.outlineVariant.withValues(alpha: .55),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(RadiusToken.pill),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildBody(context, cs, empty: empty, live: live),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 预览底板色：完成后掺一点主色，形成极浅的「已生成」底色
  Color _surfaceColor(ColorScheme cs, {required bool done}) {
    final base = cs.surfaceContainerHigh.withValues(alpha: .5);
    if (!done) return base;
    return Color.alphaBlend(cs.primary.withValues(alpha: .05), base);
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme cs, {
    required bool empty,
    required bool live,
  }) {
    if (empty && live) {
      return _Skeleton(thinking: thinking, key: const ValueKey('skeleton'));
    }
    if (empty) {
      return _EmptyState(
        key: const ValueKey('empty'),
        suggestions: _suggestions,
        onPick: onQuickPick,
      );
    }
    return SingleChildScrollView(
      key: ValueKey('content_${text.hashCode}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiMarkdownPreview(data: text),
          if (!live) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: cs.outlineVariant.withValues(alpha: .5)),
            const SizedBox(height: 10),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedLock,
                  size: 12,
                  color: cs.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'note_ai.not_applied'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: cs.outline,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 空态：图标环 + 说明 + 快捷能力入口
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.suggestions, this.onPick});

  final List<NoteAiAction> suggestions;
  final ValueChanged<NoteAiAction>? onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: .6),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 21,
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'note_ai.choose_capability'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'note_ai.preview_hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.6,
                    color: cs.outline,
                  ),
            ),
          ),
          if (onPick != null && suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final a in suggestions)
                  _QuickChip(action: a, onTap: () => onPick!(a)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 空态快捷能力胶囊
class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.action, required this.onTap});

  final NoteAiAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(RadiusToken.pill),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: action.icon, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(
                action.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 生成中骨架屏 + 思考脚注
class _Skeleton extends StatelessWidget {
  const _Skeleton({super.key, this.thinking});

  final String? thinking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasThinking = thinking != null && thinking!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 10),
        const SizedBox(height: 10),
        const SkeletonLine(width: 200, height: 10),
        const SizedBox(height: 10),
        const SkeletonLine(width: 140, height: 10),
        const SizedBox(height: 18),
        const SkeletonLine(width: double.infinity, height: 10),
        const SizedBox(height: 10),
        const SkeletonLine(width: 160, height: 10),
        if (hasThinking) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  thinking!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.6,
                        color: cs.outline,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 小方形图标按钮（复制等）
class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(RadiusToken.md),
          ),
          child: Center(
            child: HugeIcon(icon: icon, size: 15, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
