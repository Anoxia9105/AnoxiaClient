/// 桌面端输入框 AI 增强气泡（Notion 式结果卡）
///
/// 锚定工具栏 ✨ 按钮下方：
/// - 动作区：一行图标 chip；选中「自定义」后就地替换成指令输入框
/// - 内容源：quill 选区（优先）或全文；发起时快照，流式期间编辑不受影响
/// - 结果区：唯一滚动容器；空态 / 生成中 / 失败 / 内容 四态
/// - Header 与底部操作固定，不随结果滚动
/// - 快捷键：⌘/Ctrl + ↵ 应用结果，Esc 关闭
library;

import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/note/presentation/widgets/note_markdown.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../ai/chat_ai_assist_core.dart';
import '../../ai/chat_ai_assist_widgets.dart';

/// 气泡内容的理想高度（受可用空间收敛）
const double _kPreferredHeight = 468;

/// 箭头长度，与 [BubbleWidget] 默认值保持一致
const double _kArrowLength = 10;

/// 弹出输入框 AI 助手气泡（锚定按钮 context）
///
/// 会根据锚点按钮在屏幕中的位置自适应箭头方向：按钮靠近屏幕底部
/// （如桌面端输入栏）时气泡自动显示在按钮上方、箭头朝下，避免被
/// 屏幕底部或键盘遮挡。
void showChatAiAssistBubble(
  BuildContext anchorContext, {
  required QuillController controller,
  required FocusNode editorFocusNode,
}) {
  final colorScheme = Theme.of(anchorContext).colorScheme;
  final screenSize = MediaQuery.sizeOf(anchorContext);
  // 桌面宽窗下取 420；窄窗按可用宽度收敛，避免溢出屏幕
  final bubbleWidth = (screenSize.width - 24).clamp(280.0, 420.0);
  Rect targetRect = Rect.fromLTWH(
    screenSize.width - 48,
    screenSize.height - 48,
    48,
    48,
  );
  try {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final global = box.localToGlobal(Offset.zero);
      targetRect = global & box.size;
    }
  } catch (_) {}
  final placement = resolveAnchoredBubblePlacement(
    targetRect: targetRect,
    screenSize: screenSize,
    bubbleWidth: bubbleWidth,
    estimatedHeight: _kPreferredHeight,
    preferRightArrow: true,
    arrowInset: 24,
    safeTop: MediaQuery.paddingOf(anchorContext).top,
  );
  // 内容高度固定，避免结果区在「有/无结果」之间跳变导致气泡上下抖动
  final contentHeight = (placement.maxHeight - _kArrowLength).clamp(
    160.0,
    _kPreferredHeight,
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
            child: BubbleWidget(
              arrowDirection: placement.arrowDirection,
              arrowOffset: placement.arrowOffset,
              backgroundColor: colorScheme.surfaceContainer,
              border: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: .8),
                width: .5,
              ),
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              contentBuilder: (_) => SizedBox(
                width: bubbleWidth,
                height: contentHeight,
                child: ChatAiAssistCard(
                  controller: controller,
                  editorFocusNode: editorFocusNode,
                  onClose: close,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ChatAiAssistCard extends StatefulWidget {
  const ChatAiAssistCard({
    super.key,
    required this.controller,
    required this.editorFocusNode,
    required this.onClose,
  });

  final QuillController controller;
  final FocusNode editorFocusNode;
  final VoidCallback onClose;

  @override
  State<ChatAiAssistCard> createState() => _ChatAiAssistCardState();
}

class _ChatAiAssistCardState extends State<ChatAiAssistCard> {
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
    // 气泡内接管 Esc / ⌘↵：HardwareKeyboard 处理器在焦点分发之前收到按键，
    // 可稳定拦截，不会被 Quill 编辑器或发送快捷键抢先消费。
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _core.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  /// Esc 关闭；有结果时 ⌘/Ctrl + ↵ 应用结果
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return true;
    }
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return false;
    final withMeta =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    // 没有可应用的结果时放行，交给输入框自己的「发送」快捷键
    if (!withMeta || _streaming || _preview.isEmpty || _failed) return false;
    _applyPrimary();
    return true;
  }

  // ---------------- 内容源 ----------------

  /// 选区是否非空（用于决定作用域徽标与主操作文案）
  bool _hasMeaningfulSelection() {
    final plain = widget.controller.document.toPlainText();
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    if (sel.start < 0 || sel.end > plain.length || sel.end <= sel.start) {
      return false;
    }
    return plain.substring(sel.start, sel.end).trim().isNotEmpty;
  }

  ({String text, int? selStart, int? selEnd}) _captureSource() {
    final plain = widget.controller.document.toPlainText();
    final sel = widget.controller.selection;
    final hasSel =
        sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= plain.length;
    if (hasSel) {
      final text = plain.substring(sel.start, sel.end).trim();
      if (text.isNotEmpty) {
        return (text: text, selStart: sel.start, selEnd: sel.end);
      }
    }
    return (text: plain.trim(), selStart: null, selEnd: null);
  }

  bool get _hasSelectionRange => _selStart != null && _selEnd != null;

  // ---------------- 流式调用 ----------------

  void _onSelectAction(ChatAiAction action) {
    if (action == ChatAiAction.custom) {
      setState(() => _action = ChatAiAction.custom);
      return;
    }
    _start(action);
  }

  void _onLangChanged(String lang) {
    final changed = lang != _targetLang;
    setState(() => _targetLang = lang);
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

  /// 预览 Markdown 转为插入用的 Delta（去掉末尾纯换行，避免多出空行）
  Delta _previewInsertionDelta() {
    final ops = markdownToDocument(_preview).toDelta().toList();
    if (ops.length > 1) {
      final last = ops.last;
      if (last.isInsert && last.data == '\n' && last.attributes == null) {
        ops.removeLast();
      }
    }
    final delta = Delta();
    for (final op in ops) {
      delta.push(op);
    }
    return delta;
  }

  int _deltaLength(Delta delta) {
    var len = 0;
    for (final op in delta.toList()) {
      final data = op.data;
      if (data is String) {
        len += data.length;
      } else {
        len += 1;
      }
    }
    return len;
  }

  /// 应用前的文档快照，供撤销还原
  ({Delta delta, TextSelection selection}) _snapshot() => (
    delta: Delta.fromJson(widget.controller.document.toDelta().toJson()),
    selection: widget.controller.selection,
  );

  void _applyPrimary() {
    if (_hasSelectionRange) {
      _applyToSelection();
    } else {
      _insertAtCursor();
    }
  }

  void _applyToSelection() {
    final s = _selStart;
    final e = _selEnd;
    if (s == null || e == null || e <= s || _preview.isEmpty) {
      return;
    }
    final delta = _previewInsertionDelta();
    if (delta.isEmpty) {
      return;
    }
    final snap = _snapshot();
    widget.controller.replaceText(
      s,
      e - s,
      delta,
      TextSelection.collapsed(offset: s + _deltaLength(delta)),
    );
    _finishApply(snap);
  }

  void _insertAtCursor() {
    if (_preview.isEmpty) {
      return;
    }
    final delta = _previewInsertionDelta();
    if (delta.isEmpty) {
      return;
    }
    final base = widget.controller.selection.baseOffset;
    final docLen = widget.controller.document.length;
    final offset = (base < 0 || base > docLen) ? docLen - 1 : base;
    // 若原文为空文档长度为1（仅含末尾换行），插入到0更符合追加到文末的预期
    final insertAt = docLen <= 1 ? 0 : offset;
    final snap = _snapshot();
    widget.controller.replaceText(
      insertAt,
      0,
      delta,
      TextSelection.collapsed(offset: insertAt + _deltaLength(delta)),
    );
    _finishApply(snap);
  }

  void _replaceAll() {
    if (_preview.isEmpty) {
      return;
    }
    final snap = _snapshot();
    widget.controller.document = markdownToDocument(_preview);
    _finishApply(snap);
  }

  void _finishApply(({Delta delta, TextSelection selection}) snap) {
    // 写回是破坏性的（尤其「替换全部」），给一次后悔窗口
    final controller = widget.controller;
    Toast.showActionToast(
      'chat_ai.undo_hint'.tr(),
      actionLabel: 'chat_ai.undo_action'.tr(),
      onAction: () {
        controller.document = Document.fromDelta(snap.delta);
        controller.updateSelection(snap.selection, ChangeSource.local);
      },
    );
    widget.onClose();
    widget.editorFocusNode.requestFocus();
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
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChatAiAssistHeader(
            compact: true,
            scopeText: _hasMeaningfulSelection()
                ? 'chat_ai.scope_selection'.tr()
                : 'chat_ai.scope_all'.tr(),
            onClose: widget.onClose,
          ),
          const SizedBox(height: 9),
          // 自定义指令就地替换动作行，不额外撑高气泡
          if (_action == ChatAiAction.custom)
            ChatAiAssistCustomInput(
              controller: _customCtrl,
              enabled: !_streaming,
              autofocus: true,
              onSubmit: () => _start(ChatAiAction.custom),
            )
          else
            ChatAiAssistActionRow(
              selected: _action,
              enabled: !_streaming,
              onSelect: _onSelectAction,
            ),
          if (_action == ChatAiAction.translate) ...[
            const SizedBox(height: 3),
            ChatAiAssistLangField(
              value: _targetLang,
              enabled: !_streaming,
              onChanged: _onLangChanged,
            ),
          ],
          const SizedBox(height: 9),
          if (_showResultHeader) ...[
            ChatAiAssistResultHeader(
              compact: true,
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
              compact: true,
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

  Widget _buildFooter() {
    if (_streaming) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.stop_generate'.tr(),
        style: ChatAiAssistCtaStyle.stop,
        compact: true,
        onTap: _stop,
      );
    }
    if (_failed) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.regenerate'.tr(),
        icon: HugeIcons.strokeRoundedRefresh01,
        style: ChatAiAssistCtaStyle.danger,
        compact: true,
        onTap: _rerun,
      );
    }
    if (_preview.isEmpty) {
      return ChatAiAssistPrimaryCta(
        label: 'chat_ai.replace_selection'.tr(),
        style: ChatAiAssistCtaStyle.disabled,
        compact: true,
        onTap: null,
      );
    }
    return Row(
      children: [
        Expanded(
          child: ChatAiAssistPrimaryCta(
            label: _hasSelectionRange
                ? 'chat_ai.replace_selection'.tr()
                : 'chat_ai.insert_cursor'.tr(),
            compact: true,
            trailingHint: _applyShortcutHint,
            onTap: _applyPrimary,
          ),
        ),
        // 无选区时才提供「替换全部」——破坏性操作，用危险色区分
        if (!_hasSelectionRange) ...[
          const SizedBox(width: 7),
          SizedBox(
            width: 96,
            child: ChatAiAssistGhostButton(
              label: 'chat_ai.replace_all'.tr(),
              danger: true,
              onTap: _replaceAll,
            ),
          ),
        ],
      ],
    );
  }
}

/// 应用快捷键提示：Windows/Linux 用 Ctrl，macOS 用 ⌘
String get _applyShortcutHint {
  final isApple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return isApple ? '⌘↵' : 'Ctrl+↵';
}
