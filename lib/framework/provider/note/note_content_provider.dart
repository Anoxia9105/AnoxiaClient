import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_content_provider.g.dart';

/// 保存状态
enum NoteSaveState {
  /// 空闲（未改动）
  idle,

  /// 正在保存
  saving,

  /// 已保存
  saved,

  /// 保存失败
  failed,
}

/// 当前编辑会话
class NoteEditSession {
  final int noteId;
  final int? folderId;
  final String title;
  final String content;
  final String plainText;
  final bool dirty;
  final NoteSaveState saveState;
  final DateTime? lastSavedAt;

  /// 全文重新加载的代次；同一笔记还原后也必须重建编辑器。
  final int generation;

  const NoteEditSession({
    required this.noteId,
    required this.folderId,
    required this.title,
    required this.content,
    required this.plainText,
    required this.dirty,
    required this.saveState,
    required this.lastSavedAt,
    this.generation = 0,
  });

  NoteEditSession copyWith({
    int? noteId,
    int? Function()? folderId,
    String? title,
    String? content,
    String? plainText,
    bool? dirty,
    NoteSaveState? saveState,
    DateTime? Function()? lastSavedAt,
  }) {
    return NoteEditSession(
      noteId: noteId ?? this.noteId,
      folderId: folderId != null ? folderId() : this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      dirty: dirty ?? this.dirty,
      saveState: saveState ?? this.saveState,
      lastSavedAt: lastSavedAt != null ? lastSavedAt() : this.lastSavedAt,
      generation: generation,
    );
  }
}

/// 当前编辑中的笔记会话
///
/// 持有标题 / Quill Delta / 纯文本与脏标记、保存状态。
/// 编辑器 Widget 负责防抖计时，到点调用 [save] 落库。
@Riverpod(keepAlive: true)
class NoteSessionService extends _$NoteSessionService {
  /// 进行中的保存 Future，防止并发提交
  Future<bool>? _saveInflight;
  int _generation = 0;
  int? _restoringNoteId;

  @override
  NoteEditSession? build() => null;

  /// 打开（或切换）笔记会话
  void open(NoteDoc doc) {
    state = NoteEditSession(
      noteId: doc.id,
      folderId: doc.folderId,
      title: doc.title,
      content: doc.content,
      plainText: doc.plainText,
      dirty: false,
      saveState: NoteSaveState.idle,
      lastSavedAt: doc.updatedAt,
      generation: ++_generation,
    );
  }

  /// 清空会话（切换 / 关闭编辑器）
  void close() {
    state = null;
  }

  /// 更新标题
  void updateTitle(String title) {
    final current = state;
    if (current == null ||
        current.noteId == _restoringNoteId ||
        current.title == title) {
      return;
    }
    state = current.copyWith(
      title: title,
      dirty: true,
      saveState: NoteSaveState.idle,
    );
  }

  /// 更新正文（Delta JSON + 纯文本）
  void updateContent({required String content, required String plainText}) {
    final current = state;
    if (current == null ||
        current.noteId == _restoringNoteId ||
        (current.content == content && current.plainText == plainText)) {
      return;
    }
    state = current.copyWith(
      content: content,
      plainText: plainText,
      dirty: true,
      saveState: NoteSaveState.idle,
    );
  }

  /// 立即保存当前会话
  ///
  /// 返回是否成功；并发调用自动去重。
  Future<bool> save() async {
    final current = state;
    if (current == null) return false;
    if (current.noteId == _restoringNoteId) return false;
    if (!current.dirty) return true;

    state = current.copyWith(saveState: NoteSaveState.saving);

    return _saveInflight ??= _doSave().whenComplete(() => _saveInflight = null);
  }

  Future<bool> _doSave() async {
    final current = state;
    if (current == null) return false;
    final repo = ref.read(noteRepositoryProvider);
    final ok = await repo.saveNote(
      current.noteId,
      title: current.title,
      content: current.content,
      plainText: current.plainText,
    );

    if (!ref.mounted) return ok;
    final latest = state;
    if (latest == null ||
        latest.noteId != current.noteId ||
        latest.generation != current.generation) {
      return ok;
    }

    final unchanged =
        latest.title == current.title &&
        latest.content == current.content &&
        latest.plainText == current.plainText;

    state = latest.copyWith(
      dirty: !ok || !unchanged,
      saveState: ok ? NoteSaveState.saved : NoteSaveState.failed,
      lastSavedAt: () => ok ? DateTime.now() : latest.lastSavedAt,
    );
    return ok;
  }

  /// 还原与自动保存互斥，先等已发出的保存结束，再替换会话全文。
  /// 未提交的旧编辑器回调在此期间不能再次写入历史版本。
  Future<bool> restoreVersion(int noteId, int version) async {
    if (_restoringNoteId != null) return false;
    _restoringNoteId = noteId;
    final generation = state?.generation;
    try {
      final saving = _saveInflight;
      if (saving != null && !await saving) return false;
      if (!ref.mounted) return false;
      final repo = ref.read(noteRepositoryProvider);
      if (!await repo.restoreVersion(noteId, version)) return false;
      final doc = await repo.getNote(noteId);
      if (ref.mounted &&
          state?.noteId == noteId &&
          state?.generation == generation) {
        open(doc);
      }
      return true;
    } finally {
      _restoringNoteId = null;
    }
  }
}
