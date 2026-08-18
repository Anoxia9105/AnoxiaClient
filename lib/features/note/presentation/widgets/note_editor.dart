import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_quill_actions.dart';
import 'note_quill_image_build.dart';
import 'note_toolbar.dart';

/// 记事本编辑器
///
/// 负责标题 + 富文本正文的编辑，1.5s 防抖自动保存到会话，状态条展示
/// 保存状态与字数统计。会话切换时通过 ValueKey(noteId) 重建内部编辑器。
///
/// 支持斜杠命令：在行首（或空白后）输入 `/` 会弹出命令选择菜单，
/// 可直接执行加粗、标题、列表、引用、链接、图片等操作。
class NoteEditor extends ConsumerWidget {
  const NoteEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(noteSessionServiceProvider);
    if (session == null) {
      return const _NoteEditorEmpty();
    }
    return NoteEditorBody(key: ValueKey(session.noteId), session: session);
  }
}

/// 单篇笔记编辑主体（按 noteId 区分实例）
class NoteEditorBody extends ConsumerStatefulWidget {
  final NoteEditSession session;

  const NoteEditorBody({super.key, required this.session});

  @override
  ConsumerState<NoteEditorBody> createState() => _NoteEditorBodyState();
}

class _NoteEditorBodyState extends ConsumerState<NoteEditorBody> {
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _disposed = false;
  int _wordCount = 0;

  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  // ---- 斜杠命令状态 ----
  int? _slashTriggerIndex;
  String _slashQuery = '';
  OverlayEntry? _slashOverlay;
  Offset? _slashAnchorGlobal;
  double _slashLineHeight = 24;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _initEditor(widget.session);
  }

  @override
  void didUpdateWidget(covariant NoteEditorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 会话切换（noteId 变化）时重建编辑器
    if (oldWidget.session.noteId != widget.session.noteId) {
      _teardownEditor();
      _initEditor(widget.session);
    }
  }

  void _initEditor(NoteEditSession session) {
    final delta = _tryDecodeDelta(session.content);
    _quillController = QuillController(
      document: delta,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController!.addListener(_onQuillChanged);
    _wordCount = session.plainText.length;
  }

  Document _tryDecodeDelta(String content) {
    try {
      final json = jsonDecode(content);
      if (json is List) return Document.fromJson(json);
    } catch (_) {
      // 忽略损坏数据，回退到空文档
    }
    return Document();
  }

  void _teardownEditor() {
    _dismissSlashMenu();
    _debounce?.cancel();
    _debounce = null;
    _quillController?.removeListener(_onQuillChanged);
    _quillController?.dispose();
    _quillController = null;
  }

  void _onQuillChanged() {
    final controller = _quillController;
    if (controller == null || _disposed) return;

    final delta = jsonEncode(controller.document.toDelta().toJson());
    final plain = controller.document.toPlainText();
    final notifier = ref.read(noteSessionServiceProvider.notifier);
    notifier.updateContent(content: delta, plainText: plain);

    final count = plain.length;
    if (count != _wordCount) {
      setState(() => _wordCount = count);
    }
    _scheduleSave();
    _updateSlashMenu(controller);
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (_disposed || !mounted) return;
      ref.read(noteSessionServiceProvider.notifier).save();
    });
  }

  void _onFocusChanged() {
    // 编辑器失焦时关闭斜杠命令菜单
    if (!_focusNode.hasFocus && _slashOverlay != null) {
      _dismissSlashMenu();
    }
  }

  // ======================= 斜杠命令 =======================

  static final RegExp _queryCharRegex = RegExp(
    r'^[a-zA-Z0-9#_\-\u4e00-\u9fff]$',
  );

  /// 根据当前光标位置决定是否打开 / 更新 / 关闭斜杠命令菜单。
  void _updateSlashMenu(QuillController controller) {
    if (_disposed) return;

    final selection = controller.selection;
    final text = controller.document.toPlainText();
    final overlay = _slashOverlay;

    if (overlay == null) {
      // 菜单未打开：探测是否刚输入了行首的 /
      if (!selection.isCollapsed) return;
      final caret = selection.baseOffset;
      final slashPos = caret - 1;
      if (slashPos < 0 || slashPos >= text.length || text[slashPos] != '/') {
        return;
      }
      final prev = slashPos == 0 ? '' : text[slashPos - 1];
      final atLineStart = prev.isEmpty ||
          prev == '\n' ||
          prev == ' ' ||
          prev == '\t';
      if (!atLineStart) return;
      // 代码块内不触发斜杠命令
      if (controller
          .getSelectionStyle()
          .attributes
          .containsKey(Attribute.codeBlock.key)) {
        return;
      }
      _slashTriggerIndex = slashPos;
      _slashQuery = '';
      final entry = OverlayEntry(builder: _buildSlashOverlay);
      _slashOverlay = entry;
      Overlay.maybeOf(context)?.insert(entry);
      _refreshSlashAnchor();
      return;
    }

    // 菜单已打开：继续过滤 / 关闭
    if (!selection.isCollapsed) {
      _dismissSlashMenu();
      return;
    }
    final trigger = _slashTriggerIndex;
    if (trigger == null) {
      _dismissSlashMenu();
      return;
    }
    final caret = selection.baseOffset;
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
    overlay.markNeedsBuild();
    _refreshSlashAnchor();
  }

  void _refreshSlashAnchor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_slashOverlay == null || _disposed) return;
      _computeSlashAnchor();
      _slashOverlay?.markNeedsBuild();
    });
  }

  void _computeSlashAnchor() {
    final editor = _editorKey.currentState?.renderEditor;
    final controller = _quillController;
    if (editor == null || controller == null) return;
    final caret = controller.selection.baseOffset;
    try {
      final position = TextPosition(offset: caret);
      final rect = editor.getLocalRectForCaret(position);
      _slashAnchorGlobal = editor.localToGlobal(rect.topLeft);
      _slashLineHeight = editor.preferredLineHeight(position);
    } catch (_) {
      // 布局未就绪时忽略，保留上一次锚点
    }
  }

  void _dismissSlashMenu() {
    _slashOverlay?.remove();
    _slashOverlay = null;
    _slashTriggerIndex = null;
    _slashQuery = '';
  }

  Future<void> _applySlashCommand(_SlashCommand cmd) async {
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

  List<_SlashCommand> _slashCommands() {
    return [
      _SlashCommand(
        'toolbar_bold',
        const ['b', 'bold', '加粗'],
        Icons.format_bold,
        (context, ref, controller, focusNode) {
          noteToggleInline(controller, Attribute.bold);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_italic',
        const ['i', 'italic', '斜体'],
        Icons.format_italic,
        (context, ref, controller, focusNode) {
          noteToggleInline(controller, Attribute.italic);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_underline',
        const ['u', 'underline', '下划线'],
        Icons.format_underlined,
        (context, ref, controller, focusNode) {
          noteToggleInline(controller, Attribute.underline);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_strikethrough',
        const ['s', 'strike', '删除线'],
        Icons.format_strikethrough,
        (context, ref, controller, focusNode) {
          noteToggleInline(controller, Attribute.strikeThrough);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_inline_code',
        const ['code', 'inline', '行内代码'],
        Icons.code,
        (context, ref, controller, focusNode) {
          noteToggleInline(controller, Attribute.inlineCode);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_clear_format',
        const ['clear', '清除'],
        Icons.format_clear,
        (context, ref, controller, focusNode) {
          noteClearFormat(controller);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_header_h1',
        const ['h1', '标题1', '#'],
        Icons.title,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.h1);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_header_h2',
        const ['h2', '标题2', '##'],
        Icons.title,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.h2);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_header_h3',
        const ['h3', '标题3', '###'],
        Icons.title,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.h3);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_header_normal',
        const ['p', 'normal', '正文'],
        Icons.text_fields,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.clone(Attribute.header, null));
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_header_code',
        const ['codeblock', '代码块'],
        Icons.data_object,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.codeBlock);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_bullet_list',
        const ['ul', 'bullet', '无序'],
        Icons.format_list_bulleted,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.ul);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_ordered_list',
        const ['ol', 'ordered', '有序'],
        Icons.format_list_numbered,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.ol);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_task_list',
        const ['task', 'todo', '任务'],
        Icons.checklist,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.checked);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_quote',
        const ['quote', '引用'],
        Icons.format_quote,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.blockQuote);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_link',
        const ['link', '链接'],
        Icons.link,
        (context, ref, controller, focusNode) =>
            noteSetLink(context, controller, focusNode),
      ),
      _SlashCommand(
        'note_image',
        const ['img', 'image', '图片'],
        Icons.image,
        (context, ref, controller, focusNode) =>
            noteInsertImage(context, ref, controller, focusNode),
      ),
      _SlashCommand(
        'note_align_left',
        const ['left', '左'],
        Icons.format_align_left,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.leftAlignment);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_align_center',
        const ['center', '居中'],
        Icons.format_align_center,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.centerAlignment);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_align_right',
        const ['right', '右'],
        Icons.format_align_right,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.rightAlignment);
          return Future.value();
        },
      ),
      _SlashCommand(
        'note_align_justify',
        const ['justify', '两端'],
        Icons.format_align_justify,
        (context, ref, controller, focusNode) {
          controller.formatSelection(Attribute.justifyAlignment);
          return Future.value();
        },
      ),
      _SlashCommand(
        'toolbar_text_color',
        const ['color', '颜色'],
        Icons.palette,
        (context, ref, controller, focusNode) => notePickColor(
          context,
          controller,
          focusNode,
          background: false,
        ),
      ),
      _SlashCommand(
        'toolbar_bg_color',
        const ['bg', 'background', '背景'],
        Icons.format_color_fill,
        (context, ref, controller, focusNode) => notePickColor(
          context,
          controller,
          focusNode,
          background: true,
        ),
      ),
    ];
  }

  bool _slashMatches(_SlashCommand cmd, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (cmd.keywords.any((k) => k.toLowerCase().startsWith(q))) return true;
    return cmd.labelKey.tr().toLowerCase().contains(q);
  }

  Widget _buildSlashOverlay(BuildContext overlayContext) {
    final theme = Theme.of(overlayContext);
    final colorScheme = theme.colorScheme;
    final commands =
        _slashCommands().where((c) => _slashMatches(c, _slashQuery)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const popupWidth = 268.0;
        const maxPopupHeight = 300.0;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final anchor = _slashAnchorGlobal ?? Offset.zero;
        final lineHeight = _slashLineHeight <= 0 ? 24.0 : _slashLineHeight;

        var left = anchor.dx;
        if (left + popupWidth > screenWidth - 8) {
          left = math.max(8.0, screenWidth - popupWidth - 8);
        }
        if (left < 8) left = 8;

        final contentHeight = commands.isEmpty
            ? 56.0
            : math.min(maxPopupHeight, commands.length * 42.0 + 8);
        var top = anchor.dy + lineHeight + 4;
        if (top + contentHeight > screenHeight - 8) {
          top = math.max(8.0, anchor.dy - contentHeight - 4);
        }
        if (top < 8) top = 8;

        return Positioned(
          left: left,
          top: top,
          width: popupWidth,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surface,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: commands.isEmpty
                  ? SizedBox(
                      height: contentHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearchRemove,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'note_slash_no_result'.tr(),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: contentHeight,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: commands.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 40,
                          endIndent: 8,
                          color: colorScheme.outlineVariant.withValues(alpha: .4),
                        ),
                        itemBuilder: (context, index) {
                          final cmd = commands[index];
                          return _SlashCommandItem(
                            label: cmd.labelKey.tr(),
                            icon: cmd.icon,
                            onTap: () => _applySlashCommand(cmd),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _dismissSlashMenu();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _quillController?.removeListener(_onQuillChanged);
    _quillController?.dispose();
    _titleController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(noteSessionServiceProvider);
    final controller = _quillController;
    if (session == null || controller == null) {
      return const _NoteEditorEmpty();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          ref.read(noteSessionServiceProvider.notifier).save();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _titleControllerOf(session),
              onChanged: (value) {
                ref.read(noteSessionServiceProvider.notifier).updateTitle(value);
                _scheduleSave();
              },
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'note_untitled'.tr(),
                hintStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 4),
          NoteToolbar(controller: controller, focusNode: _focusNode),
          Expanded(
            child: QuillEditor.basic(
              focusNode: _focusNode,
              controller: controller,
              config: QuillEditorConfig(
                enableSelectionToolbar: false,
                placeholder: 'note_content_placeholder'.tr(),
                autoFocus: false,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                customStyles: QuillStyleConfig.get(context),
                editorKey: _editorKey,
                embedBuilders: [
                  NoteQuillImageBuild(),
                ],
              ),
            ),
          ),
          _buildStatusBar(context, session, colorScheme),
        ],
      ),
    );
  }

  /// 标题输入框控制器（延迟到真正需要时创建，避免重复创建泄漏）
  TextEditingController? _titleController;
  TextEditingController _titleControllerOf(NoteEditSession session) {
    return _titleController ??= TextEditingController(text: session.title);
  }

  Widget _buildStatusBar(
    BuildContext context,
    NoteEditSession session,
    ColorScheme colorScheme,
  ) {
    final saveLabel = switch (session.saveState) {
      NoteSaveState.saving => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 6),
            Text('note_autosave_saving'.tr()),
          ],
        ),
      NoteSaveState.saved => Text(
          'note_autosave_saved'.tr(
            args: [_formatTime(session.lastSavedAt)],
          ),
        ),
      NoteSaveState.failed => TextButton.icon(
          onPressed: () =>
              ref.read(noteSessionServiceProvider.notifier).save(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedRefresh01,
            size: 14,
          ),
          label: Text('note_autosave_failed'.tr()),
        ),
      NoteSaveState.idle => Text('note_autosave_idle'.tr()),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: saveLabel),
          Text(
            'note_word_count'.tr(args: [_wordCount.toString()]),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// 斜杠命令项
class _SlashCommand {
  final String labelKey;
  final List<String> keywords;
  final IconData icon;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    QuillController controller,
    FocusNode focusNode,
  ) action;

  const _SlashCommand(
    this.labelKey,
    this.keywords,
    this.icon,
    this.action,
  );
}

/// 斜杠命令菜单中的单项
class _SlashCommandItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SlashCommandItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 未选中笔记时的空态
class _NoteEditorEmpty extends StatelessWidget {
  const _NoteEditorEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: .18),
                  colorScheme.primary.withValues(alpha: .05),
                ],
              ),
              border: Border.all(color: colorScheme.primary.withValues(alpha: .15)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNote01,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'note_editor_empty_title'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'note_editor_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}