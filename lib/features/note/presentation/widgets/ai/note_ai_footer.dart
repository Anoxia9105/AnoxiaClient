/// 记事本 AI 操作栏（手机端弹框 / 桌面端侧栏共用）
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

import '../note_ai_action.dart';

/// 常驻底部操作栏。
///
/// 替代原先「运行按钮 + 最多 3 个通栏应用按钮纵向堆叠」的做法：
/// - 主按钮是页面上唯一的实心按钮，是明确的视觉终点；
/// - 有结果时主按钮直接变成当前动作的主去向（替换选中 / 替换全文 / 追加 / 设为标题）；
/// - 次级操作（复制 / 重新生成）收进第二行，不再与破坏性操作抢注意力；
/// - 生成中主按钮变为「停止生成」，可中断 SSE，不再只能干等。
class NoteAiFooter extends StatelessWidget {
  const NoteAiFooter({
    super.key,
    required this.preview,
    required this.streaming,
    required this.failed,
    required this.action,
    required this.hasSelection,
    required this.onRun,
    required this.onStop,
    required this.onReplaceSelection,
    required this.onReplaceAll,
    required this.onAppendToEnd,
    required this.onApplyAsTitle,
    required this.onCopy,
  });

  final String preview;
  final bool streaming;
  final bool failed;
  final NoteAiAction? action;

  /// 打开面板时是否有选区，决定结果的主去向
  final bool hasSelection;

  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onReplaceSelection;
  final VoidCallback onReplaceAll;
  final VoidCallback onAppendToEnd;
  final VoidCallback onApplyAsTitle;
  final VoidCallback onCopy;

  bool get _hasResult => preview.isNotEmpty && !streaming;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingToken.lg,
        SpacingToken.md,
        SpacingToken.lg,
        SpacingToken.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed) ...[
            _ErrorBanner(message: 'note_ai.failed'.tr()),
            const SizedBox(height: SpacingToken.sm),
          ],
          _buildPrimary(context, cs),
          if (_hasResult && action != null) ...[
            const SizedBox(height: SpacingToken.sm),
            Row(
              children: [
                Expanded(
                  child: _FooterButton(
                    label: 'note_ai.copy'.tr(),
                    icon: HugeIcons.strokeRoundedCopy01,
                    onTap: onCopy,
                    kind: _ButtonKind.ghost,
                  ),
                ),
                const SizedBox(width: SpacingToken.sm),
                Expanded(
                  child: _FooterButton(
                    label: 'note_ai.regenerate'.tr(),
                    icon: HugeIcons.strokeRoundedRefresh01,
                    onTap: onRun,
                    kind: _ButtonKind.tonal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimary(BuildContext context, ColorScheme cs) {
    // 生成中：主按钮变为可中断的「停止生成」
    if (streaming) {
      return _FooterButton(
        label: 'note_ai.stop'.tr(),
        icon: HugeIcons.strokeRoundedStop,
        onTap: onStop,
        kind: _ButtonKind.stop,
      );
    }

    // 失败：主按钮为「重试」
    if (failed) {
      return _FooterButton(
        label: 'note_ai.retry'.tr(),
        icon: HugeIcons.strokeRoundedRefresh01,
        onTap: onRun,
        kind: _ButtonKind.primary,
      );
    }

    // 有结果：主按钮即当前动作的主去向
    if (_hasResult && action != null) {
      final a = action!;
      if (a == NoteAiAction.title) {
        return _FooterButton(
          label: 'note_ai.use_as_title'.tr(),
          icon: HugeIcons.strokeRoundedText,
          onTap: onApplyAsTitle,
          kind: _ButtonKind.primary,
        );
      }
      // 续写 / 扩写 且无选区 → 只能追加到文末
      if (!hasSelection &&
          (a == NoteAiAction.continueWrite || a == NoteAiAction.expand)) {
        return _FooterButton(
          label: 'note_ai.append'.tr(),
          icon: HugeIcons.strokeRoundedNoteAdd,
          onTap: onAppendToEnd,
          kind: _ButtonKind.primary,
        );
      }
      if (hasSelection) {
        return _FooterButton(
          label: 'note_ai.replace_selection'.tr(),
          icon: HugeIcons.strokeRoundedFileEdit,
          onTap: onReplaceSelection,
          kind: _ButtonKind.primary,
        );
      }
      return _FooterButton(
        label: 'note_ai.replace_all'.tr(),
        icon: HugeIcons.strokeRoundedFileEdit,
        onTap: onReplaceAll,
        kind: _ButtonKind.primary,
      );
    }

    // 空闲：未选能力时置灰
    return _FooterButton(
      label: 'note_ai.run'.tr(),
      icon: HugeIcons.strokeRoundedSparkles,
      onTap: action == null ? null : onRun,
      kind: _ButtonKind.primary,
    );
  }
}

enum _ButtonKind { primary, tonal, ghost, stop }

/// 底栏按钮：高度 42、圆角 12，主按钮带渐变 + 内高光 + 同色投影
class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.kind,
  });

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final _ButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    Color baseColor;
    Gradient? gradient;
    Color fg;
    Color border;
    List<BoxShadow>? shadow;

    if (kind == _ButtonKind.primary && !disabled) {
      baseColor = cs.primary;
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(Colors.white.withValues(alpha: .10), cs.primary),
          Color.alphaBlend(Colors.black.withValues(alpha: .04), cs.primary),
        ],
      );
      fg = cs.onPrimary;
      border = Colors.transparent;
      shadow = [
        BoxShadow(
          color: cs.primary.withValues(alpha: .34),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ];
    } else if (kind == _ButtonKind.primary) {
      // 未选能力：主按钮置灰，但保留位置不让布局跳动
      baseColor = cs.surfaceContainerHighest;
      gradient = null;
      fg = cs.outline;
      border = Colors.transparent;
      shadow = null;
    } else if (kind == _ButtonKind.tonal) {
      baseColor = cs.primary.withValues(alpha: .15);
      gradient = null;
      fg = cs.primary;
      border = cs.primary.withValues(alpha: .28);
      shadow = null;
    } else if (kind == _ButtonKind.stop) {
      baseColor = cs.surfaceContainerHighest;
      gradient = null;
      fg = cs.error;
      border = cs.error.withValues(alpha: .32);
      shadow = null;
    } else {
      // ghost
      baseColor = cs.surfaceContainerHigh;
      gradient = null;
      fg = cs.onSurfaceVariant;
      border = cs.outlineVariant.withValues(alpha: .8);
      shadow = null;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: gradient == null ? baseColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(color: border),
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: 15, color: fg),
              const SizedBox(width: SpacingToken.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.1,
                        color: fg,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 失败提示条
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingToken.md,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: cs.error.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 15,
            color: cs.error,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11.5, color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
