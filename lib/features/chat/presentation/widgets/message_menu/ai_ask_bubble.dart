/// 消息「问AI」锚定气泡（双端统一）
///
/// 从长按/右键菜单进入，把该条消息作为上下文发起持久会话：
/// - 快捷动作：解释 / 总结 / 翻译（可展开语言选择）
/// - 流式回答区 + 追问输入框（conversationId 续传多轮）
/// - 复制结果；关闭时中止上游流
library;

import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../chatinput/ai/chat_ai_assist_core.dart';

/// 支持的翻译目标语言（专有名词不做 i18n）
const _translateLangs = <String>['中文', 'English', '日本語', '한국어', 'Français'];

/// 弹出「问AI」气泡。
///
/// [anchor] 为菜单触发点的全局坐标；[quotedText] 为消息纯文本。
void showAiAskBubble({
  required Offset anchor,
  required String quotedText,
}) {
  final clean = quotedText.trim();
  if (clean.isEmpty) return;

  CancelFunc closeFn = () {};
  closeFn = BotToast.showAttachedWidget(
    target: anchor,
    preferDirection: PreferDirection.bottomLeft,
    onlyOne: true,
    ignoreContentClick: false,
    attachedBuilder: (_) {
      // attachedBuilder 不提供 BuildContext，从平台视图取逻辑宽度
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final screenWidth =
          view.physicalSize.width / view.devicePixelRatio;
      final isNarrow = screenWidth < 520;
      return Material(
        color: Colors.transparent,
        child: _AiAskBubbleCard(
          quotedText: clean,
          maxWidth: isNarrow ? screenWidth - 24 : 420.0,
          onClose: () => closeFn(),
        ),
      );
    },
  );
}

class _AiAskBubbleCard extends StatefulWidget {
  const _AiAskBubbleCard({
    required this.quotedText,
    required this.maxWidth,
    required this.onClose,
  });

  final String quotedText;
  final double maxWidth;
  final VoidCallback onClose;

  @override
  State<_AiAskBubbleCard> createState() => _AiAskBubbleCardState();
}

class _AiAskBubbleCardState extends State<_AiAskBubbleCard> {
  final _core = ChatAiAssistCore();
  final _followCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _answer = '';
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
      '以下是收到的消息：\n"""\n${widget.quotedText}\n"""\n\n$task';

  void _askExplain() => _startChat(_buildFirstPrompt('请解释这条消息的含义与语气。'));

  void _askSummarize() => _startChat(_buildFirstPrompt('请总结这条消息的要点。'));

  void _askTranslate(String lang) {
    setState(() => _showLangs = false);
    _startChat(
      _buildFirstPrompt('请把这条消息翻译成$lang，只输出译文，不要解释。'),
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
      _failed = false;
      _errorText = null;
      _streaming = true;
    });
    _core.chat(
      message: message,
      conversationId: _conversationId,
      handlers: ChatAiStreamHandlers(
        onDelta: (_) => mountedSetState(),
        onDone: (conversationId, fullText) {
          if (!mounted) return;
          if (conversationId.isNotEmpty) _conversationId = conversationId;
          setState(() {
            _answer = fullText;
            _streaming = false;
          });
          _scrollToBottom();
        },
        onError: (msg) {
          if (!mounted) return;
          setState(() {
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
      arrowDirection: AxisDirection.up,
      arrowOffset: 24,
      backgroundColor: _cs.surface,
      border: BorderSide(color: _cs.outlineVariant.withValues(alpha: .8), width: .5),
      borderRadius: BorderRadius.circular(12),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .16),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      contentBuilder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
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
                    style: TextStyle(fontSize: 11.5, color: _cs.error),
                  ),
                ),
              const SizedBox(height: 8),
              _buildFollowUpRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 15, color: _cs.primary),
        const SizedBox(width: 6),
        Text('chat_ai.ask'.tr(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.quotedText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: _cs.onSurfaceVariant),
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
      borderRadius: BorderRadius.circular(999),
      hoverColor: _cs.primary.withValues(alpha: .08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon, size: 12, color: _cs.primary),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(fontSize: 11.5, color: _cs.onSurface)),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: empty
          ? Center(
              child: Text('chat_ai.empty_tip'.tr(),
                  style: TextStyle(fontSize: 11.5, color: _cs.onSurfaceVariant)),
            )
          : SingleChildScrollView(
              controller: _scrollCtrl,
              child: SelectableText(
                _answer,
                style: TextStyle(fontSize: 12.5, height: 1.55, color: _cs.onSurface),
              ),
            ),
    );
  }

  Widget _buildFollowUpRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _followCtrl,
            enabled: !_streaming,
            style: const TextStyle(fontSize: 12.5),
            onSubmitted: (_) => _sendFollowUp(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'chat_ai.followup_hint'.tr(),
              hintStyle: TextStyle(
                  fontSize: 11.5, color: _cs.onSurfaceVariant.withValues(alpha: .6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _cs.outlineVariant.withValues(alpha: .6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    size: 15,
                    color: _cs.onPrimary,
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
        borderRadius: BorderRadius.circular(6),
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
