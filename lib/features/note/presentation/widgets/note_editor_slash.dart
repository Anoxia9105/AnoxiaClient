part of 'note_editor.dart';

/// 斜杠命令交互混入
///
/// 负责斜杠触发检测、菜单锚点计算、键盘导航与命令执行，
/// 与 [NoteEditorTitleArea] / [NoteEditorStatusBar] 等展示部件解耦，
/// 保持主编辑器体的编辑生命周期清晰。
mixin _SlashMenuMixin on ConsumerState<NoteEditorBody> {
  int? _slashTriggerIndex;
  String _slashQuery = '';
  OverlayEntry? _slashOverlay;
  Offset? _slashAnchorGlobal;
  double _slashLineHeight = 24;

  /// 键盘上下键选中的命令下标（高亮项）
  int _slashSelectedIndex = 0;

  /// 指针是否悬停在菜单上（点击菜单项时编辑器会失焦，需要据此阻止菜单被关闭）
  bool _slashPointerInside = false;

  /// 菜单列表滚动控制器（键盘导航时把选中项滚进可视区）
  final ScrollController _slashScrollController = ScrollController();

  /// 是否已排期待打开菜单（延迟到本帧结束后插入，避免与编辑区重建同帧竞争）
  bool _slashPending = false;

  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  static final RegExp _queryCharRegex = RegExp(
    r'^[a-zA-Z0-9#_\-\u4e00-\u9fff]$',
  );

  /// 根据当前光标位置决定是否打开 / 更新 / 关闭斜杠命令菜单。
  void _updateSlashMenu(QuillController controller) {
    if (_disposed) return;
    try {
      final selection = controller.selection;
      final text = controller.document.toPlainText();
      final textLength = text.length;
      // IME 组合输入等场景下 selection 可能短暂超前于文档长度，
      // 统一收敛到文档末尾，避免 text 越界访问被 catch 静默吞掉导致菜单不弹。
      final caret = math.min(selection.baseOffset, textLength);
      final overlay = _slashOverlay;

      if (overlay == null) {
        // 菜单未打开但已排期：继续过滤查询字符
        final trigger = _slashTriggerIndex;
        if (_slashPending && trigger != null && selection.isCollapsed) {
          if (caret <= trigger) {
            _dismissSlashMenu();
            return;
          }
          for (var i = trigger + 1; i < caret; i++) {
            if (!_queryCharRegex.hasMatch(text[i])) {
              _dismissSlashMenu();
              return;
            }
          }
          _slashQuery = text.substring(trigger + 1, caret);
          return;
        }
        _slashPending = false;

        // 探测是否刚输入了行首的 /
        if (!selection.isCollapsed) return;
        final slashPos = caret - 1;
        if (slashPos < 0 || slashPos >= textLength || text[slashPos] != '/') {
          return;
        }
        final prev = slashPos == 0 ? '' : text[slashPos - 1];
        final atLineStart =
            prev.isEmpty || prev == '\n' || prev == ' ' || prev == '\t';
        if (!atLineStart) return;
        // 代码块内不触发斜杠命令
        if (controller.getSelectionStyle().attributes.containsKey(
          Attribute.codeBlock.key,
        )) {
          return;
        }
        _slashTriggerIndex = slashPos;
        _slashQuery = '';
        // 延迟到本帧结束（编辑区重建完成、布局就绪）后再插入菜单
        _slashPending = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _openSlashMenu());
        return;
      }

      // 菜单已打开：继续过滤 / 关闭
      if (!selection.isCollapsed) {
        _dismissSlashMenu();
        return;
      }
      final currentTrigger = _slashTriggerIndex;
      if (currentTrigger == null) {
        _dismissSlashMenu();
        return;
      }
      if (caret <= currentTrigger) {
        _dismissSlashMenu();
        return;
      }
      for (var i = currentTrigger + 1; i < caret; i++) {
        if (!_queryCharRegex.hasMatch(text[i])) {
          _dismissSlashMenu();
          return;
        }
      }
      _slashQuery = text.substring(currentTrigger + 1, caret);
      // 过滤结果变少时收敛选中项，避免高亮落到列表外
      final filteredCount = _filteredSlashCommands().length;
      if (_slashSelectedIndex >= filteredCount) {
        _slashSelectedIndex = math.max(0, filteredCount - 1);
      }
      overlay.markNeedsBuild();
      _refreshSlashAnchor();
    } catch (_) {
      // 斜杠菜单的任何异常都不允许破坏编辑器
      _dismissSlashMenu();
    }
  }

  /// 本帧结束后真正插入斜杠命令菜单
  void _openSlashMenu() {
    if (_disposed || !_slashPending) return;
    _slashPending = false;
    if (_slashOverlay != null) return;
    _slashSelectedIndex = 0;
    _computeSlashAnchor();
    final entry = OverlayEntry(builder: _buildSlashOverlay);
    _slashOverlay = entry;
    Overlay.maybeOf(context)?.insert(entry);
    // 菜单打开期间接管 ↑/↓/回车/ESC 做键盘导航。
    // HardwareKeyboard 处理器在焦点分发之前收到按键，可稳定拦截，
    // 不会被编辑器内部的按键处理抢先消费。
    HardwareKeyboard.instance.addHandler(_slashHardwareKeyHandler);
  }

  /// 键盘导航：↑/↓ 移动选中项，回车执行，ESC 关闭。
  /// 返回 true 表示已消费该按键（编辑器不再移动光标/插入换行）。
  bool _slashHardwareKeyHandler(KeyEvent event) {
    if (_slashOverlay == null) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    final commands = _filteredSlashCommands();
    if (key == LogicalKeyboardKey.arrowDown) {
      if (commands.isNotEmpty) {
        _slashSelectedIndex = (_slashSelectedIndex + 1) % commands.length;
        _syncSlashSelection();
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (commands.isNotEmpty) {
        _slashSelectedIndex =
            (_slashSelectedIndex - 1 + commands.length) % commands.length;
        _syncSlashSelection();
      }
      return true;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (commands.isNotEmpty) {
        final index = _slashSelectedIndex.clamp(0, commands.length - 1);
        _applySlashCommand(commands[index]);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      _dismissSlashMenu();
      return true;
    }
    return false;
  }

  /// 键盘移动选中项后：刷新菜单高亮 + 把选中项滚动到可视区。
  void _syncSlashSelection() {
    _slashOverlay?.markNeedsBuild();
    if (_slashScrollController.hasClients) {
      // 估算行高 43（42 内容 + 1 分隔线）
      final target = _slashSelectedIndex * 43.0;
      final max = _slashScrollController.position.maxScrollExtent;
      _slashScrollController.animateTo(
        target.clamp(0.0, max),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
      );
    }
  }

  /// 当前过滤后的命令列表
  List<SlashCommand> _filteredSlashCommands() {
    return buildNoteSlashCommands()
        .where((c) => slashCommandMatches(c, _slashQuery))
        .toList();
  }

  void _refreshSlashAnchor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_slashOverlay == null || _disposed) return;
      _computeSlashAnchor();
      _slashOverlay?.markNeedsBuild();
    });
  }

  void _computeSlashAnchor() {
    final controller = _quillController;
    if (controller == null) return;
    try {
      final editor = _editorKey.currentState?.renderEditor;
      if (editor == null) return;
      final caret = controller.selection.baseOffset;
      final position = TextPosition(offset: caret);
      final rect = editor.getLocalRectForCaret(position);
      _slashAnchorGlobal = editor.localToGlobal(rect.topLeft);
      _slashLineHeight = editor.preferredLineHeight(position);
    } catch (_) {
      // 布局未就绪时忽略，保留上一次锚点
    }
  }

  void _dismissSlashMenu() {
    _slashPending = false;
    HardwareKeyboard.instance.removeHandler(_slashHardwareKeyHandler);
    _slashOverlay?.remove();
    _slashOverlay = null;
    _slashTriggerIndex = null;
    _slashQuery = '';
    _slashSelectedIndex = 0;
    _slashPointerInside = false;
  }

  Future<void> _applySlashCommand(SlashCommand cmd) async {
    final controller = _quillController;
    final trigger = _slashTriggerIndex;
    if (controller == null || trigger == null) return;
    final end = controller.selection.baseOffset;

    _dismissSlashMenu();
    if (end > trigger) {
      controller.replaceText(
        trigger,
        end - trigger,
        '',
        TextSelection.collapsed(offset: trigger),
      );
    }
    await cmd.action(context, ref, controller, _focusNode);
    if (mounted) _focusNode.requestFocus();
  }

  Widget _buildSlashOverlay(BuildContext overlayContext) {
    return NoteSlashMenuOverlay(
      commands: _filteredSlashCommands(),
      anchor: _slashAnchorGlobal,
      lineHeight: _slashLineHeight,
      selectedIndex: _slashSelectedIndex,
      scrollController: _slashScrollController,
      onSelected: _applySlashCommand,
      onPointerEnter: () => _slashPointerInside = true,
      onPointerExit: () => _slashPointerInside = false,
    );
  }

  // 这些由主类提供，混入通过同库私有访问解析
  QuillController? get _quillController;
  FocusNode get _focusNode;
  bool get _disposed;
}
