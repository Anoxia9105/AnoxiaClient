// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note_ai_panel.dart';
import 'note_editor_parts.dart';
import 'note_editor_interactions.dart';
import 'note_editor_widgets.dart';
import 'note_markdown_io.dart';
import 'note_pdf_io.dart';
import 'note_quill_actions.dart';
import 'note_quill_divider_build.dart';
import 'note_quill_image_build.dart';
import 'note_search_panel.dart';
import 'note_share.dart';
import 'note_toolbar.dart';
import 'note_versions_dialog.dart';

part 'note_editor_slash.dart';

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
      return const NoteEditorEmpty();
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

class _NoteEditorBodyState extends ConsumerState<NoteEditorBody>
    with _SlashMenuMixin {
  @override
  QuillController? _quillController;
  @override
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  @override
  bool _disposed = false;
  int _wordCount = 0;
  Uint8List? _lastHandledImageBytes;
  DateTime? _lastImagePasteTime;

  /// 会话服务实例（懒加载缓存一次，后续复用）
  NoteSessionService? _cachedSessionService;

  NoteSessionService get _sessionService {
    final cached = _cachedSessionService;
    if (cached != null) return cached;
    final created = ref.read(noteSessionServiceProvider.notifier);
    _cachedSessionService = created;
    return created;
  }

  /// 右侧「在文档中查找」面板是否展开
  bool _showSearch = false;

  /// 右侧 AI 面板是否展开（与搜索面板互斥）
  bool _showAi = false;

  /// 标题输入框控制器（延迟到真正需要时创建，避免重复创建泄漏）
  TextEditingController? _titleController;
  TextEditingController _titleControllerOf(NoteEditSession session) {
    return _titleController ??= TextEditingController(text: session.title);
  }

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

  bool _isDuplicateImagePaste(Uint8List bytes) {
    final lastBytes = _lastHandledImageBytes;
    final lastTime = _lastImagePasteTime;
    if (lastBytes == null || lastTime == null) return false;
    if (DateTime.now().difference(lastTime) > const Duration(seconds: 2)) {
      return false;
    }
    if (lastBytes.length != bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != lastBytes[i]) return false;
    }
    return true;
  }

  void _initEditor(NoteEditSession session) {
    final delta = _tryDecodeDelta(session.content);
    late final QuillController controller;
    controller = QuillController(
      document: delta,
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (_isDuplicateImagePaste(imageBytes)) return null;
            if (!mounted) return null;
            _lastHandledImageBytes = Uint8List.fromList(imageBytes);
            _lastImagePasteTime = DateTime.now();
            await notePasteImageBytes(context, ref, controller, imageBytes);
            return null;
          },
        ),
      ),
    );
    _quillController = controller;
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
    _showSearch = false;
    _showAi = false;
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
    // toPlainText 会把嵌入（分割线/图片）输出为 U+FFFC 对象占位符，
    // 直接入库会让左侧列表预览显示成乱码方块（看起来像"obj"），这里剔除
    final plain = controller.document.toPlainText().replaceAll(
      Embed.kObjectReplacementCharacter,
      '',
    );
    final notifier = _sessionService;
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
      _saveNow();
    });
  }

  /// 立即保存当前改动（取消待执行的防抖）。
  ///
  /// 保存成功后静默刷新树列表，让左侧列表的标题 / 预览及时更新，
  /// 避免「改了标题列表里还是旧标题」的观感。
  Future<void> _saveNow() async {
    _debounce?.cancel();
    _debounce = null;
    // 网络异常时 save 会抛错，这里兜底为失败，避免影响编辑流程
    final ok = await _sessionService.save().catchError((Object _) => false);
    if (!ok || _disposed || !mounted) return;
    ref.read(noteTreeServiceProvider.notifier).refresh(quiet: true);
  }

  void _onFocusChanged() {
    // 编辑器失焦时关闭斜杠命令菜单；
    // 但点击菜单项导致的失焦（指针在菜单内）不能关——否则菜单会在点击
    // 完成前被卸载，onTap 永远触发不了（桌面端点击菜单项"没反应"的根因）。
    if (!_focusNode.hasFocus && _slashOverlay != null && !_slashPointerInside) {
      _dismissSlashMenu();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    HardwareKeyboard.instance.removeHandler(_slashHardwareKeyHandler);
    _dismissSlashMenu();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _quillController?.removeListener(_onQuillChanged);
    _quillController?.dispose();
    _titleController?.dispose();
    _slashScrollController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(noteSessionServiceProvider);
    final controller = _quillController;
    if (session == null || controller == null) {
      return const NoteEditorEmpty();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Focus(
        autofocus: false,
        onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyF) {
          _toggleSearchPanel();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          _sessionService.save().catchError((Object _) => false);
          return KeyEventResult.handled;
        }
        // 粘贴不再拦截 Ctrl/Cmd+V — Quill v11 内置剪贴板处理已保留加粗/颜色等
        // 行内样式；外部拦截反而导致 HtmlToDelta 转换失败后回退纯文本，丢失格式。
        // 图片粘贴由 QuillClipboardConfig.onImagePaste 回调处理（见 _initEditor）。
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        child: NoteEditorTitleArea(
                          session: session,
                          titleController: _titleControllerOf(session),
                          onTitleChanged: (value) {
                            _sessionService.updateTitle(value);
                            _scheduleSave();
                          },
                          onTitleSubmitted: (_) => _saveNow(),
                          onSaveNow: _saveNow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      NoteToolbar(
                        controller: controller,
                        focusNode: _focusNode,
                        searchActive: _showSearch,
                        onSearchToggle: _toggleSearchPanel,
                        aiActive: _showAi,
                        onAiToggle: _toggleAiPanel,
                      ),
                      Expanded(
                        child: QuillEditor.basic(
                          focusNode: _focusNode,
                          controller: controller,
                          scrollController: _scrollController,
                          config: QuillEditorConfig(
                            enableSelectionToolbar: false,
                            placeholder: 'note_content_placeholder'.tr(),
                            autoFocus: false,
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                            customStyles: QuillStyleConfig.get(
                              context,
                              checkboxBuilder: const NoteTaskCheckboxBuilder(),
                              listLineSpacing: const VerticalSpacing(3, 3),
                            ),
                            textSpanBuilder: noteTextSpanBuilder,
                            editorKey: _editorKey,
                            embedBuilders: [
                              NoteQuillImageBuild(),
                              NoteQuillDividerBuild(),
                            ],
                            customShortcuts: const {
                              // 关闭 flutter_quill 自带的查找弹窗（带遮罩），
                              // Ctrl+F 交由外层 Focus 切换右侧查找面板。
                              SingleActivator(
                                LogicalKeyboardKey.keyF,
                                control: true,
                              ): DoNothingIntent(),
                              SingleActivator(
                                LogicalKeyboardKey.keyF,
                                meta: true,
                              ): DoNothingIntent(),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showSearch)
                  NoteSearchPanel(
                    controller: controller,
                    editorFocusNode: _focusNode,
                    onClose: () => setState(() => _showSearch = false),
                  )
                else if (_showAi)
                  NoteAiPanel(
                    controller: controller,
                    noteId: session.noteId,
                    onTitle: (t) => _titleControllerOf(session).text = t,
                    onClose: () => setState(() => _showAi = false),
                  ),
              ],
            ),
          ),
          NoteEditorStatusBar(
            session: session,
            wordCount: _wordCount,
            onSaveRetry: () => _sessionService.save(),
            onShare: _shareNote,
            onImportMarkdown: _importMarkdown,
            onExportMarkdown: _exportMarkdown,
            onExportPdf: _exportPdf,
            onShowVersions: (ctx) =>
                showNoteVersionsDialog(ctx, session.noteId),
          ),
        ],
        ),
      ),
    );
  }

  /// 切换右侧查找面板；与 AI 面板互斥，关闭时清除查找高亮选区。
  void _toggleSearchPanel() {
    final willShow = !_showSearch;
    setState(() {
      _showSearch = willShow;
      if (willShow) _showAi = false;
    });
    if (_showSearch) return;
    final controller = _quillController;
    if (controller != null) {
      final base = controller.selection.baseOffset;
      controller.updateSelection(
        TextSelection.collapsed(offset: base),
        ChangeSource.local,
      );
    }
    _focusNode.requestFocus();
  }

  /// 切换右侧 AI 面板；与搜索面板互斥
  void _toggleAiPanel() {
    setState(() {
      final willShow = !_showAi;
      _showAi = willShow;
      if (willShow) _showSearch = false;
    });
    if (!_showAi) _focusNode.requestFocus();
  }

  String _formatTime(DateTime? dt) => formatNoteTime(dt);

  Future<void> _shareNote(BuildContext context) async {
    final session = ref.read(noteSessionServiceProvider);
    if (session == null) return;
    await shareNoteToChat(
      context,
      ref,
      noteId: session.noteId,
      title: session.title,
      content: session.plainText,
      updatedAt: session.lastSavedAt?.millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _importMarkdown(BuildContext context) async {
    final controller = _quillController;
    if (controller == null) return;
    if (!await confirmImportMarkdown(context)) return;
    await importNoteMarkdown(ref, controller: controller);
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final controller = _quillController;
    if (controller == null) return;
    await exportNoteMarkdown(
      ref,
      title: widget.session.title,
      controller: controller,
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final controller = _quillController;
    if (controller == null) return;
    await exportNotePdf(
      context,
      title: widget.session.title,
      deltaJson: jsonEncode(controller.document.toDelta().toJson()),
      updatedAtLabel: _formatTime(widget.session.lastSavedAt),
    );
  }
}
