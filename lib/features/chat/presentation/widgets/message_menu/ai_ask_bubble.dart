/// 消息「问AI」锚定气泡（双端统一）
///
/// 从长按/右键菜单进入，把该条消息作为上下文发起持久会话：
/// - 快捷动作：解释 / 总结 / 翻译（可展开语言选择）
/// - 流式回答区 + 追问输入框（conversationId 续传多轮）
/// - 复制结果；关闭时中止上游流
library;

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../chatinput/ai/chat_ai_assist_core.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 支持的翻译目标语言（专有名词不做 i18n）
const _translateLangs = <String>['中文', 'English', '日本語', '한국어', 'Français'];

AnchoredBubblePlacement resolveAiAskBubblePlacement({
  required Offset anchor,
  required Size screenSize,
  required double bubbleWidth,
  required double estimatedHeight,
  double safeTop = 0,
}) {
  return resolveAnchoredBubblePlacement(
    targetRect: Rect.fromLTWH(anchor.dx, anchor.dy, 0, 0),
    screenSize: screenSize,
    bubbleWidth: bubbleWidth,
    estimatedHeight: estimatedHeight,
    preferRightArrow: anchor.dx >= screenSize.width / 2,
    arrowInset: 24,
    safeTop: safeTop,
  );
}

/// 弹出「问AI」气泡。
///
/// [anchor] 为菜单触发点的全局坐标；[quotedText] 为消息纯文本。
/// 会根据锚点在屏幕中的位置自适应箭头方向：锚点靠近底部（下方空间
/// 不足）时气泡显示在锚点上方、箭头朝下，避免气泡与输入框重叠或被截断。
void showAiAskBubble({
  required BuildContext context,
  required Offset anchor,
  required String quotedText,
}) {
  final clean = quotedText.trim();
  if (clean.isEmpty) return;

  // 自适应：估算气泡高度约 380（含头部与最大 280 的回答区）
  final screenSize = MediaQuery.sizeOf(context);
  final bubbleWidth = (screenSize.width - 24).clamp(0.0, 420.0);
  const estimatedHeight = 380.0;
  final placement = resolveAiAskBubblePlacement(
    anchor: anchor,
    screenSize: screenSize,
    bubbleWidth: bubbleWidth,
    estimatedHeight: estimatedHeight,
    safeTop: MediaQuery.paddingOf(context).top,
  );

  BotToast.showEnhancedWidget(
    onlyOne: true,
    clickClose: true,
    ignoreContentClick: false,
    enableKeyboardSafeArea: false,
    backgroundColor: Colors.transparent,
    toastBuilder: (close) => Stack(
      children: [
        Positioned(
          left: placement.left,
          top: placement.showBelow ? placement.anchorY : null,
          bottom: placement.showBelow
              ? null
              : screenSize.height - placement.anchorY,
          width: bubbleWidth,
          child: Material(
            color: Colors.transparent,
            child: _AiAskBubbleCard(
              quotedText: clean,
              width: bubbleWidth,
              maxHeight: placement.maxHeight,
              arrowDirection: placement.arrowDirection,
              arrowOffset: placement.arrowOffset,
              onClose: close,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AiAskBubbleCard extends StatefulWidget {
  const _AiAskBubbleCard({
    required this.quotedText,
    required this.width,
    required this.maxHeight,
    required this.onClose,
    required this.arrowOffset,
    this.arrowDirection = AxisDirection.up,
  });

  final String quotedText;
  final double width;
  final double maxHeight;
  final VoidCallback onClose;
  final AxisDirection arrowDirection;
  final double arrowOffset;

  @override
  State<_AiAskBubbleCard> createState() => _AiAskBubbleCardState();
}

class _AiAskBubbleCardState extends State<_AiAskBubbleCard> {
  final _core = ChatAiAssistCore();
  final _followCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _answer = '';
  String? _thinking;
  bool _streaming = false;
  bool _failed = false;
  String? _errorText;
  bool _showLangs = false;
  String? _conversationId;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void dispose() {
    _core.dispose();
    _followCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------- 提示词组装 ----------------

  String _buildFirstPrompt(String task) =>
      'ai_ask_context'.tr(args: [widget.quotedText, task]);

  void _askExplain() => _startChat(_buildFirstPrompt('ai_ask_explain'.tr()));

  void _askSummarize() => _startChat(_buildFirstPrompt('ai_ask_summarize'.tr()));

  void _askTranslate(String lang) {
    setState(() => _showLangs = false);
    _startChat(
      _buildFirstPrompt('ai_ask_translate'.tr(args: [lang])),
    );
  }

  void _sendFollowUp() {
    final text = _followCtrl.text.trim();
    if (text.isEmpty || _streaming) return;
    _followCtrl.clear();
    _startChat(text);
  }

  // ---------------- 流式调用 ----------------

  void _startChat(String message) {
    setState(() {
      _answer = '';
      _thinking = null;
      _failed = false;
      _errorText = null;
      _streaming = true;
    });
    _core.chat(
      message: message,
      conversationId: _conversationId,
      handlers: ChatAiStreamHandlers(
        onDelta: (fullText) {
          if (!mounted) return;
          setState(() => _answer = fullText);
          _scrollToBottom();
        },
        onThinking: (thinking) {
          if (!mounted) return;
          setState(() => _thinking = thinking);
          _scrollToBottom();
        },
        onDone: (conversationId, fullText) {
          if (!mounted) return;
          if (conversationId.isNotEmpty) _conversationId = conversationId;
          setState(() {
            _answer = fullText;
            _thinking = null;
            _streaming = false;
          });
          _scrollToBottom();
        },
        onError: (msg) {
          if (!mounted) return;
          setState(() {
            _thinking = null;
            _streaming = false;
            _failed = true;
            _errorText = msg;
          });
        },
      ),
    );
  }

  void mountedSetState() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  Future<void> _copyAnswer() async {
    if (_answer.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _answer));
    if (mounted) Toast.showToast('chat_ai.copied'.tr(), type: ToastType.success);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return BubbleWidget(
      arrowDirection: widget.arrowDirection,
      arrowOffset: widget.arrowOffset,
      backgroundColor: _cs.surface,
      border: BorderSide(color: _cs.outlineVariant.withValues(alpha: .8), width: .5),
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .16),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      contentBuilder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight - 10),
        child: SingleChildScrollView(
          child: SizedBox(
            width: widget.width,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildActionChips(),
                  if (_showLangs) ...[
                    const SizedBox(height: 6),
                    _buildLangChips(),
                  ],
                  const SizedBox(height: 8),
                  _buildAnswerArea(),
                  if (_failed && _errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith( color: _cs.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildFollowUpRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _cs.primaryContainer.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(RadiusToken.md),
        border: Border.all(color: _cs.primary.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _cs.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(RadiusToken.sm),
            ),
            child: HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 13, color: _cs.primary),
          ),
          const SizedBox(width: 6),
          Text('chat_ai.ask'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -.2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.quotedText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith( color: _cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          _iconBtn(
            tooltip: 'chat_ai.copy'.tr(),
            icon: HugeIcons.strokeRoundedCopy01,
            onTap: _answer.isEmpty ? null : _copyAnswer,
          ),
          _iconBtn(
            tooltip: 'close'.tr(),
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip('chat_ai.explain'.tr(), HugeIcons.strokeRoundedMessageMultiple01,
            _streaming ? null : _askExplain),
        _chip('chat_ai.summarize'.tr(), HugeIcons.strokeRoundedFileValidation,
            _streaming ? null : _askSummarize),
        _chip('chat_ai.translate'.tr(), HugeIcons.strokeRoundedTranslate,
            _streaming ? null : () => setState(() => _showLangs = !_showLangs)),
      ],
    );
  }

  Widget _buildLangChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final lang in _translateLangs)
          _chip(lang, null, _streaming ? null : () => _askTranslate(lang)),
      ],
    );
  }

  Widget _chip(String label, List<List<dynamic>>? icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      hoverColor: _cs.primary.withValues(alpha: .08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon, size: 12, color: _cs.primary),
              const SizedBox(width: 4),
            ],
            Text(label, style: Theme.of(context).textTheme.bodySmall!.copyWith( color: _cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerArea() {
    final empty = _answer.isEmpty && !_streaming;
    return Container(
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 280),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: _cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: empty
          ? Center(
              child: Text('chat_ai.empty_tip'.tr(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith( color: _cs.onSurfaceVariant)),
            )
          : _streaming && _answer.isEmpty
              ? _buildSkeleton()
              : SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: AiMarkdownPreview(data: _answer),
                ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 200, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 160, height: 11),
        const SizedBox(height: 12),
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 180, height: 11),
        if (_thinking != null && _thinking!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_thinking!,
              style: Theme.of(context).textTheme.labelSmall!.copyWith( color: _cs.onSurfaceVariant.withValues(alpha: .6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  Widget _buildFollowUpRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _followCtrl,
            enabled: !_streaming,
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => _sendFollowUp(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'chat_ai.followup_hint'.tr(),
              hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith( color: _cs.onSurfaceVariant.withValues(alpha: .6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                borderSide: BorderSide(color: _cs.outlineVariant.withValues(alpha: .6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                borderSide: BorderSide(color: _cs.primary, width: 1.1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _streaming
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : InkWell(
                onTap: _sendFollowUp,
                borderRadius: BorderRadius.circular(RadiusToken.md),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cs.primary,
                    borderRadius: BorderRadius.circular(RadiusToken.md),
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 16,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSent,
                        size: 13,
                        color: _cs.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _iconBtn({
    required String tooltip,
    required List<List<dynamic>> icon,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: HugeIcon(
            icon: icon,
            size: 14,
            color: onTap == null
                ? _cs.onSurfaceVariant.withValues(alpha: .35)
                : _cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
