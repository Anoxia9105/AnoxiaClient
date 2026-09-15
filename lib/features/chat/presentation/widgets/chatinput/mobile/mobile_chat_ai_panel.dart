/// 移动端输入框 AI 助手面板
///
/// 挂载在 `ChatBottomPanelContainer` 的 `ai` 面板类型，独占纵向高度：
/// - 内容源：输入框选区（优先）或全文
/// - 动作区：3×2 图标网格（润色/扩写/续写/翻译/精简/自定义）
/// - 翻译目标语言：内联 pill + 下拉，不再叠一层 chip
/// - 结果区：唯一滚动容器；空态 / 生成中 / 失败 / 内容 四态
/// - 底部主操作固定：应用结果 / 停止生成 / 重新生成
/// - 结果应用：替换选区 / 插入光标 / 替换全文，且应用后 5 秒内可撤销
library;

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../ai/chat_ai_assist_core.dart';
import '../ai/chat_ai_assist_widgets.dart';

class MobileChatAiPanel extends StatefulWidget {
  const MobileChatAiPanel({
    super.key,
    required this.inputController,
    required this.onClose,
  });

  final MobileTextInputController inputController;
  final VoidCallback onClose;

  @override
  State<MobileChatAiPanel> createState() => _MobileChatAiPanelState();
}

class _MobileChatAiPanelState extends State<MobileChatAiPanel> {
  final _core = ChatAiAssistCore();
  final _customCtrl = TextEditingController();

  ChatAiAction? _action;
  String _targetLang = 'English';

  /// 发起时快照：内容源与选区范围
  String _sourceText = '';
  int? _selStart;
  int? _selEnd;

  String _preview = '';
  String? _thinking;
  bool _streaming = false;
  bool _failed = false;
  String? _errorText;
  bool _copiedTick = false;

  @override
  void initState() {
    super.initState();
    // 让顶部作用域徽标随输入框选区实时变化
    widget.inputController.textController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    widget.inputController.textController.removeListener(_handleInputChanged);
    _core.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  // ---------------- 内容源 ----------------

  bool _hasMeaningfulSelection() {
    final tc = widget.inputController.textController;
    final sel = tc.selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    if (sel.start < 0 || sel.end > tc.text.length || sel.end <= sel.start) {
      return false;
    }
    return tc.text.substring(sel.start, sel.end).trim().isNotEmpty;
  }

  String get _scopeText => _hasMeaningfulSelection()
      ? 'chat_ai.scope_selection'.tr()
      : 'chat_ai.scope_all'.tr();

  ({String text, int? selStart, int? selEnd}) _captureSource() {
    final tc = widget.inputController.textController;
    final text = tc.text;
    final sel = tc.selection;
    final hasSel =
        sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length;
    if (hasSel) {
      final picked = text.substring(sel.start, sel.end).trim();
      if (picked.isNotEmpty) {
        return (text: picked, selStart: sel.start, selEnd: sel.end);
      }
    }
    return (text: text.trim(), selStart: null, selEnd: null);
  }

  bool get _hasSelectionRange => _selStart != null && _selEnd != null;

  // ---------------- 流式调用 ----------------

  void _onSelectAction(ChatAiAction action) {
    if (action == ChatAiAction.custom) {
      // 自定义指令需要先输入再执行
      setState(() => _action = ChatAiAction.custom);
      return;
    }
    _start(action);
  }

  void _onLangChanged(String lang) {
    final changed = lang != _targetLang;
    setState(() => _targetLang = lang);
    // 已有翻译结果时切换语言直接重跑，避免多一次点击
    if (changed && !_streaming && _preview.isNotEmpty) {
      _start(ChatAiAction.translate);
    }
  }

  void _start(ChatAiAction action) {
    final src = _captureSource();
    if (src.text.isEmpty) {
      Toast.showToast('chat_ai.input_empty'.tr(), type: ToastType.warning);
      return;
    }
    if (action == ChatAiAction.custom && _customCtrl.text.trim().isEmpty) {
      Toast.showToast(
        'chat_ai.instruction_required'.tr(),
        type: ToastType.warning,
      );
      return;
    }

    setState(() {
      _action = action;
      _sourceText = src.text;
      _selStart = src.selStart;
      _selEnd = src.selEnd;
      _preview = '';
      _thinking = null;
      _failed = false;
      _errorText = null;
      _copiedTick = false;
      _streaming = true;
    });

    _runTransform(action);
  }

  /// 同参数重跑（失败后重试 / 结果不满意换一版）
  void _rerun() {
    final action = _action;
    if (action == null || _streaming) return;
    setState(() {
      _preview = '';
      _thinking = null;
      _failed = false;
      _errorText = null;
      _copiedTick = false;
      _streaming = true;
    });
    _runTransform(action);
  }

  /// 中断当前流式生成，保留已生成的部分内容
  void _stop() {
    _core.cancel();
    if (!mounted) return;
    setState(() {
      _streaming = false;
      _thinking = null;
    });
  }

  void _runTransform(ChatAiAction action) {
    _core.transform(
      action: action,
      content: _sourceText,
      targetLang: _targetLang,
      customInstruction: _customCtrl.text.trim(),
      handlers: ChatAiStreamHandlers(
        onDelta: (fullText) {
          if (!mounted) return;
          setState(() => _preview = fullText);
        },
        onThinking: (thinking) {
          if (!mounted) return;
          setState(() => _thinking = thinking);
        },
        onDone: (_, fullText) {
          if (!mounted) return;
          setState(() {
            _preview = fullText;
            _thinking = null;
            _streaming = false;
          });
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

  // ---------------- 应用结果 ----------------

  /// 原子写回并登记可撤销快照
  ///
  /// [MobileTextInputController.replaceAllText] 会同步空态与 @提及区间，
  /// 避免直接给 `textController.value` 赋值造成状态漂移。
  void _writeBack(String newText, int cursorOffset) {
    final controller = widget.inputController;
    final tc = controller.textController;
    final undoText = tc.text;
    final undoSelection = tc.selection;
    final undoMentions = List<MentionSpan>.of(tc.mentions);

    controller.replaceAllText(newText, cursorOffset: cursorOffset);
    _offerUndo(undoText, undoSelection, undoMentions);
    widget.onClose();
  }

  void _offerUndo(
    String text,
    TextSelection selection,
    List<MentionSpan> mentions,
  ) {
    Toast.showActionToast(
      'chat_ai.undo_hint'.tr(),
      actionLabel: 'chat_ai.undo_action'.tr(),
      onAction: () {
        widget.inputController.restoreText(text, selection, mentions);
      },
    );
  }

  void _applyToSelection() {
    final s = _selStart;
    final e = _selEnd;
    if (s == null || e == null || e <= s || _preview.isEmpty) return;
    final current = widget.inputController.textController.text;
    // 选区快照后用户可能又编辑过，越界则放弃替换
    if (e > current.length) return;
    final combined = current.substring(0, s) + _preview + current.substring(e);
    _writeBack(combined, s + _preview.length);
  }

  void _insertAtCursor() {
    if (_preview.isEmpty) return;
    final tc = widget.inputController.textController;
    var offset = tc.selection.baseOffset;
    if (offset < 0 || offset > tc.text.length) offset = tc.text.length;
    final combined =
        tc.text.substring(0, offset) + _preview + tc.text.substring(offset);
    _writeBack(combined, offset + _preview.length);
  }

  void _replaceAll() {
    if (_preview.isEmpty) return;
    _writeBack(_preview, _preview.length);
  }

  Future<void> _copyPreview() async {
    if (_preview.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _preview));
    if (!mounted) return;
    setState(() => _copiedTick = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copiedTick = false);
    });
  }

  // ---------------- UI ----------------

  ChatAiResultView get _view {
    if (_failed) return ChatAiResultView.error;
    if (_preview.isNotEmpty) return ChatAiResultView.content;
    if (_streaming) return ChatAiResultView.loading;
    return ChatAiResultView.empty;
  }

  bool get _showResultHeader => _preview.isNotEmpty || _failed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGrabber(),
          ChatAiAssistHeader(scopeText: _scopeText, onClose: widget.onClose),
          const SizedBox(height: 10),
          ChatAiAssistActionGrid(
            selected: _action,
            enabled: !_streaming,
            onSelect: _onSelectAction,
          ),
          if (_action == ChatAiAction.custom) ...[
            const SizedBox(height: 8),
            ChatAiAssistCustomInput(
              controller: _customCtrl,
              enabled: !_streaming,
              onSubmit: () => _start(ChatAiAction.custom),
            ),
          ],
          if (_action == ChatAiAction.translate) ...[
            const SizedBox(height: 4),
            ChatAiAssistLangField(
              value: _targetLang,
              enabled: !_streaming,
              onChanged: _onLangChanged,
            ),
          ],
          const SizedBox(height: 9),
          if (_showResultHeader) ...[
            ChatAiAssistResultHeader(
              streaming: _streaming,
              sourceChars: _sourceText.runes.length,
              resultChars: _preview.runes.length,
              copied: _copiedTick,
              onCopy: _copyPreview,
              onRegenerate: _streaming ? null : _rerun,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ChatAiAssistResultBody(
              view: _view,
              preview: _preview,
              thinking: _thinking,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildGrabber() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 8, bottom: 2),
        decoration: BoxDecoration(
          color: cs.outline.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(RadiusToken.pill),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_streaming) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.stop_generate'.tr(),
        style: ChatAiAssistCtaStyle.stop,
        onTap: _stop,
      );
    }
    if (_failed) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.regenerate'.tr(),
        icon: HugeIcons.strokeRoundedRefresh01,
        style: ChatAiAssistCtaStyle.danger,
        onTap: _rerun,
      );
    }
    if (_preview.isEmpty) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.replace_selection'.tr(),
        style: ChatAiAssistCtaStyle.disabled,
        onTap: null,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChatAiAssistPrimaryCta(
          label: _hasSelectionRange
              ? 'chat_ai.replace_selection'.tr()
              : 'chat_ai.insert_cursor'.tr(),
          onTap: _hasSelectionRange ? _applyToSelection : _insertAtCursor,
        ),
        // 无选区时才提供「替换全部」——破坏性操作，用危险色区分
        if (!_hasSelectionRange) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              ChatAiAssistGhostButton(
                label: 'chat_ai.replace_all'.tr(),
                danger: true,
                expand: true,
                onTap: _replaceAll,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
