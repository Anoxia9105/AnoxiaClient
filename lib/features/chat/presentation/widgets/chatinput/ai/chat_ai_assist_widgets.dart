/// 聊天输入框 AI 助手共享展示组件
///
/// 移动端底部面板（`MobileChatAiPanel`）与桌面端锚定气泡（`ChatAiAssistCard`）
/// 复用同一套组件，仅密度不同（[compact]）：
///
/// - [ChatAiAssistHeader]      单行标题 + 作用域徽标 + 关闭
/// - [ChatAiAssistActionGrid]  3×2 图标网格（移动端）
/// - [ChatAiAssistActionRow]   一行图标 chip（桌面端）
/// - [ChatAiAssistCustomInput] 自定义指令输入
/// - [ChatAiAssistLangField]   翻译目标语言（内联 pill + 下拉，不再单开一行 chip）
/// - [ChatAiAssistResultHeader] 结果标签 + 字数变化 + 复制 / 换一版
/// - [ChatAiAssistResultBody]  结果容器（空态 / 生成中 / 失败 / 内容 四态）
/// - [ChatAiAssistPrimaryCta]  底部主操作（整行实心 / 停止 / 重新生成）
/// - [ChatAiAssistGhostButton] 次级幽灵按钮
/// - [ChatAiAssistIconButton]  小图标按钮
///
/// 颜色一律取自 `Theme.of(context).colorScheme`，自动适配亮/暗主题与
/// 16 种强调色；圆角统一走 [RadiusToken]。
library;

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'chat_ai_assist_core.dart';

/// 翻译目标语言候选
const chatAiAssistTranslateLangs = <String>[
  '中文',
  'English',
  '日本語',
  '한국어',
  'Français',
];

/// 输入框 AI 助手提供的动作顺序（移动网格 / 桌面 chip 行共用）
const chatAiAssistActions = <ChatAiAction>[
  ChatAiAction.polish,
  ChatAiAction.expand,
  ChatAiAction.continueWrite,
  ChatAiAction.translate,
  ChatAiAction.simplify,
  ChatAiAction.custom,
];

/// 动作的图标与文案键
extension ChatAiActionVisual on ChatAiAction {
  /// 动作图标（HugeIcons 描边风格，与项目其他 AI 入口保持一致）
  List<List<dynamic>> get icon => switch (this) {
    ChatAiAction.explain => HugeIcons.strokeRoundedFileSearch,
    ChatAiAction.translate => HugeIcons.strokeRoundedTranslate,
    ChatAiAction.summarize => HugeIcons.strokeRoundedFileSearch,
    ChatAiAction.polish => HugeIcons.strokeRoundedBrush,
    ChatAiAction.expand => HugeIcons.strokeRoundedExpand,
    ChatAiAction.continueWrite => HugeIcons.strokeRoundedPen01,
    ChatAiAction.simplify => HugeIcons.strokeRoundedTextClear,
    ChatAiAction.custom => HugeIcons.strokeRoundedMagicWand01,
  };

  /// 动作文案 i18n 键
  String get labelKey => switch (this) {
    ChatAiAction.explain => 'chat_ai.explain',
    ChatAiAction.translate => 'chat_ai.translate',
    ChatAiAction.summarize => 'chat_ai.summarize',
    ChatAiAction.polish => 'chat_ai.polish',
    ChatAiAction.expand => 'chat_ai.expand',
    ChatAiAction.continueWrite => 'chat_ai.continue',
    ChatAiAction.simplify => 'chat_ai.simplify',
    ChatAiAction.custom => 'chat_ai.custom',
  };
}

/// 结果区呈现形态
enum ChatAiResultView {
  /// 尚未发起（引导态）
  empty,

  /// 流式中且还没有正文（骨架 + 思考）
  loading,

  /// 有正文（流式写作中或已完成）
  content,

  /// 失败
  error,
}

// ---------------------------------------------------------------------------
// 通用小件
// ---------------------------------------------------------------------------

/// 作用域徽标：说明本次处理的是选区还是全文
class ChatAiAssistScopeBadge extends StatelessWidget {
  const ChatAiAssistScopeBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

/// 小图标按钮
class ChatAiAssistIconButton extends StatelessWidget {
  const ChatAiAssistIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 14,
    this.filled = false,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;

  /// 是否带底色（用于 Header 的关闭按钮）
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final box = size + 10;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: Container(
          width: box,
          height: box,
          decoration: filled
              ? BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                )
              : null,
          child: Center(
            child: HugeIcon(icon: icon, size: size, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header / Footer
// ---------------------------------------------------------------------------

/// 顶部标题区：单行 40/34px，作用域收成徽标，不再占两行
class ChatAiAssistHeader extends StatelessWidget {
  const ChatAiAssistHeader({
    super.key,
    required this.scopeText,
    required this.onClose,
    this.compact = false,
  });

  final String scopeText;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mark = compact ? 24.0 : 26.0;
    return SizedBox(
      height: compact ? 34 : 40,
      child: Row(
        children: [
          Container(
            width: mark,
            height: mark,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: compact ? 13 : 14,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'chat_ai.assist_title'.tr(),
            style: TextStyle(
              fontSize: compact ? 12.5 : 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(width: 8),
          // 用 Expanded + Align 吃掉剩余空间：徽标按内容自适应宽度，
          // 关闭按钮始终贴右（Flexible + Spacer 会在徽标不满时留下空隙）
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ChatAiAssistScopeBadge(text: scopeText),
            ),
          ),
          const SizedBox(width: 6),
          ChatAiAssistIconButton(
            icon: HugeIcons.strokeRoundedCancel01,
            tooltip: 'close'.tr(),
            onTap: onClose,
            size: compact ? 13 : 14,
            filled: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 动作选择
// ---------------------------------------------------------------------------

/// 动作图标卡（移动端网格单元）
class ChatAiAssistActionTile extends StatelessWidget {
  const ChatAiAssistActionTile({
    super.key,
    required this.action,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final ChatAiAction action;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    return Opacity(
      // 流式期间不可点，用透明度给出明确反馈
      opacity: enabled ? 1 : .45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: .65)
                : cs.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: .5)
                  : cs.outlineVariant.withValues(alpha: .7),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: action.icon, size: 16, color: fg),
              const SizedBox(height: 5),
              Text(
                action.labelKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.1,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 动作区（移动端 3×2 图标网格）
///
/// 相比原来的文字 `Wrap`，固定网格保证高度可控、不随语言换行跳动。
class ChatAiAssistActionGrid extends StatelessWidget {
  const ChatAiAssistActionGrid({
    super.key,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final ChatAiAction? selected;
  final ValueChanged<ChatAiAction> onSelect;

  /// 流式期间禁用（避免并发发起）
  final bool enabled;

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < chatAiAssistActions.length; i += _perRow) {
      final slice = chatAiAssistActions.skip(i).take(_perRow).toList();
      final cells = <Widget>[];
      for (var j = 0; j < _perRow; j++) {
        if (j > 0) cells.add(const SizedBox(width: 7));
        cells.add(
          Expanded(
            child: j < slice.length
                ? ChatAiAssistActionTile(
                    action: slice[j],
                    selected: selected == slice[j],
                    enabled: enabled,
                    onTap: enabled ? () => onSelect(slice[j]) : null,
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      rows.add(Row(children: cells));
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          rows[i],
        ],
      ],
    );
  }
}

/// 动作 chip（桌面端横排）
class ChatAiAssistActionChip extends StatelessWidget {
  const ChatAiAssistActionChip({
    super.key,
    required this.action,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final ChatAiAction action;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: .65)
                : cs.surfaceContainerHighest.withValues(alpha: .4),
            borderRadius: BorderRadius.circular(RadiusToken.md),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: .5)
                  : cs.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 6 个 chip 平分 420 宽气泡，图标与间距必须克制，否则文字会省略
              HugeIcon(icon: action.icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  action.labelKey.tr(),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

/// 动作区（桌面端一行图标 chip）
class ChatAiAssistActionRow extends StatelessWidget {
  const ChatAiAssistActionRow({
    super.key,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final ChatAiAction? selected;
  final ValueChanged<ChatAiAction> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < chatAiAssistActions.length; i++) {
      if (i > 0) cells.add(const SizedBox(width: 5));
      final action = chatAiAssistActions[i];
      cells.add(
        Expanded(
          child: ChatAiAssistActionChip(
            action: action,
            selected: selected == action,
            enabled: enabled,
            onTap: enabled ? () => onSelect(action) : null,
          ),
        ),
      );
    }
    return Row(children: cells);
  }
}

// ---------------------------------------------------------------------------
// 自定义指令 / 翻译语言
// ---------------------------------------------------------------------------

/// 自定义指令输入行
class ChatAiAssistCustomInput extends StatelessWidget {
  const ChatAiAssistCustomInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              hintText: 'chat_ai.custom_hint'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: enabled ? onSubmit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
            ),
            child: Text(
              'note_ai.run'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// 翻译目标语言：内联一行「翻译为 [English ⌄]」
///
/// 替代原来「点翻译再冒出一整行语言 chip」的双层堆叠。
class ChatAiAssistLangField extends StatelessWidget {
  const ChatAiAssistLangField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.primary,
    );
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            'chat_ai.target_lang'.tr(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            initialValue: value,
            tooltip: '',
            enabled: enabled,
            onSelected: onChanged,
            itemBuilder: (context) => [
              for (final lang in chatAiAssistTranslateLangs)
                PopupMenuItem<String>(
                  value: lang,
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: lang == value
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: lang == value ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                      if (lang == value)
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedTick02,
                          size: 14,
                          color: cs.primary,
                        ),
                    ],
                  ),
                ),
            ],
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                  border: Border.all(color: cs.primary.withValues(alpha: .45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: textStyle),
                    const SizedBox(width: 6),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 12,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 结果区
// ---------------------------------------------------------------------------

/// 结果标题行：标签 + 字数变化 + 复制 / 换一版
class ChatAiAssistResultHeader extends StatelessWidget {
  const ChatAiAssistResultHeader({
    super.key,
    required this.streaming,
    required this.sourceChars,
    required this.resultChars,
    required this.copied,
    required this.onCopy,
    required this.onRegenerate,
    this.compact = false,
  });

  final bool streaming;
  final int sourceChars;
  final int resultChars;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: cs.primary,
    );
    final iconSize = compact ? 12.0 : 13.0;
    return SizedBox(
      // 需容纳图标按钮（iconSize + 10 的内衬）
      height: compact ? 24 : 26,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: .62),
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedEye,
                  size: 11,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Text('chat_ai.result_label'.tr(), style: labelStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: streaming
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GeneratingDot(color: cs.primary),
                        const SizedBox(width: 5),
                        Text(
                          'chat_ai.generating'.tr(),
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(fontSize: 10, color: cs.primary),
                        ),
                      ],
                    )
                  : Text(
                      'chat_ai.char_stats'.tr(
                        args: ['$sourceChars', '$resultChars'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          ChatAiAssistIconButton(
            icon: copied
                ? HugeIcons.strokeRoundedTick02
                : HugeIcons.strokeRoundedCopy01,
            tooltip: 'chat_ai.copy'.tr(),
            onTap: onCopy,
            size: iconSize,
          ),
          ChatAiAssistIconButton(
            icon: HugeIcons.strokeRoundedRefresh01,
            tooltip: 'chat_ai.regenerate'.tr(),
            onTap: onRegenerate,
            size: iconSize,
          ),
        ],
      ),
    );
  }
}

/// 流式呼吸点
class _GeneratingDot extends StatefulWidget {
  const _GeneratingDot({required this.color});

  final Color color;

  @override
  State<_GeneratingDot> createState() => _GeneratingDotState();
}

class _GeneratingDotState extends State<_GeneratingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .25, end: 1).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// 结果容器：唯一的滚动区，四态切换
class ChatAiAssistResultBody extends StatelessWidget {
  const ChatAiAssistResultBody({
    super.key,
    required this.view,
    required this.preview,
    this.thinking,
    this.errorText,
    this.compact = false,
  });

  final ChatAiResultView view;
  final String preview;
  final String? thinking;
  final String? errorText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasResult = view == ChatAiResultView.content;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: hasResult
              ? cs.primary.withValues(alpha: .22)
              : cs.outlineVariant.withValues(alpha: .55),
        ),
        boxShadow: hasResult
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: .06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      // 单层滚动：外层容器不再套 ScrollView
      child: SingleChildScrollView(
        primary: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (view) {
            ChatAiResultView.empty => const _EmptyState(
              key: ValueKey('ai_empty'),
            ),
            ChatAiResultView.loading => ChatAiAssistSkeleton(
              key: const ValueKey('ai_loading'),
              thinking: thinking,
            ),
            ChatAiResultView.error => _ErrorState(
              key: const ValueKey('ai_error'),
              message: errorText ?? 'chat_ai.failed'.tr(),
            ),
            // 稳定 key：AnimatedSwitcher 只在「四态切换」时过渡，
            // 不会因为流式增量刷新而反复交叉淡入
            ChatAiResultView.content => AiMarkdownPreview(
              key: const ValueKey('ai_content'),
              data: preview,
            ),
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Opacity(
            opacity: .55,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 24,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'chat_ai.preview_empty'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 22,
            color: cs.error,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: cs.onSurface, height: 1.55),
          ),
          const SizedBox(height: 5),
          Text(
            'chat_ai.error_hint'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 10,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 流式骨架
class ChatAiAssistSkeleton extends StatelessWidget {
  const ChatAiAssistSkeleton({super.key, this.thinking});

  final String? thinking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasThinking = thinking != null && thinking!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 9),
        const SkeletonLine(width: 200, height: 11),
        const SizedBox(height: 9),
        const SkeletonLine(width: 160, height: 11),
        const SizedBox(height: 12),
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 9),
        const SkeletonLine(width: 180, height: 11),
        if (hasThinking) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cs.outlineVariant.withValues(alpha: .6)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedBulb,
                  size: 12,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    thinking!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontSize: 10.5,
                      height: 1.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 底部操作
// ---------------------------------------------------------------------------

/// 主操作按钮形态
enum ChatAiAssistCtaStyle {
  /// 实心主色（应用结果）
  primary,

  /// 描边危险色（停止生成）
  stop,

  /// 浅底危险色（重新生成）
  danger,

  /// 置灰不可用
  disabled,
}

/// 底部主操作：整行按钮，不随结果区滚动
class ChatAiAssistPrimaryCta extends StatelessWidget {
  const ChatAiAssistPrimaryCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.style = ChatAiAssistCtaStyle.primary,
    this.trailingHint,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final List<List<dynamic>>? icon;
  final ChatAiAssistCtaStyle style;
  final String? trailingHint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg, Color? border) = switch (style) {
      ChatAiAssistCtaStyle.primary => (cs.primary, cs.onPrimary, null),
      ChatAiAssistCtaStyle.stop => (
        Colors.transparent,
        cs.error,
        cs.error.withValues(alpha: .45),
      ),
      ChatAiAssistCtaStyle.danger => (
        cs.error.withValues(alpha: .14),
        cs.error,
        cs.error.withValues(alpha: .4),
      ),
      ChatAiAssistCtaStyle.disabled => (
        cs.primary.withValues(alpha: .35),
        cs.onPrimary,
        null,
      ),
    };
    final enabled = onTap != null && style != ChatAiAssistCtaStyle.disabled;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: Container(
        height: compact ? 36 : 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon!, size: 13, color: fg),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            if (trailingHint != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(RadiusToken.sm),
                ),
                child: Text(
                  trailingHint!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 次级幽灵按钮
class ChatAiAssistGhostButton extends StatelessWidget {
  const ChatAiAssistGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final List<List<dynamic>>? icon;

  /// 破坏性操作（如「替换全部」）用危险色区分，避免和「复制」长得一样
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = danger ? cs.error : cs.onSurface;
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.md),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: danger
              ? cs.error.withValues(alpha: .12)
              : cs.surfaceContainerHighest.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(RadiusToken.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon!, size: 13, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }
}
