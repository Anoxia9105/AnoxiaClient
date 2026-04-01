import 'package:anoxia/framework/domain/NoteTreeNode.dart';
import 'package:anoxia/framework/provider/note/repositories/note_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'note_provider.g.dart';

// ── 布局模式 ──────────────────────────────────────────────
enum NoteLayoutMode { card, tree }

// ── 全局 Repository 单例 ──────────────────────────────────
@riverpod
NoteRepository noteRepository(Ref ref) {
  return NoteRepository();
}

// ── 笔记状态 ──────────────────────────────────────────────
class NoteState {
  final List<NoteTreeNode> roots;
  final List<NoteTreeNode> flatNotes; // 所有笔记（card 视图用）
  final NoteTreeNode? selectedNode;
  final NoteLayoutMode layoutMode;
  final int cardIndex; // CardSwiper 当前索引

  const NoteState({
    this.roots = const [],
    this.flatNotes = const [],
    this.selectedNode,
    this.layoutMode = NoteLayoutMode.card,
    this.cardIndex = 0,
  });

  NoteState copyWith({
    List<NoteTreeNode>? roots,
    List<NoteTreeNode>? flatNotes,
    NoteTreeNode? selectedNode,
    bool clearSelected = false,
    NoteLayoutMode? layoutMode,
    int? cardIndex,
  }) {
    return NoteState(
      roots: roots ?? this.roots,
      flatNotes: flatNotes ?? this.flatNotes,
      selectedNode: clearSelected ? null : (selectedNode ?? this.selectedNode),
      layoutMode: layoutMode ?? this.layoutMode,
      cardIndex: cardIndex ?? this.cardIndex,
    );
  }
}

// ── 主控制器 ──────────────────────────────────────────────
@riverpod
class NoteNotifier extends _$NoteNotifier {
  late NoteRepository _repo;

  @override
  Future<NoteState> build() async {
    _repo = ref.read(noteRepositoryProvider);
    await _repo.init();
    return _loadState();
  }

  // ── 内部 ────────────────────────────────────────────────
  NoteState _loadState([
    NoteLayoutMode? mode,
    NoteTreeNode? selected,
    int cardIndex = 0,
  ]) {
    final entities = _repo.getAll();
    final flat = entities.map(NoteTreeNode.fromEntity).toList();
    final roots = buildTree(flat);
    final notes = flattenNotes(roots);
    final currentMode = mode ?? state.value?.layoutMode ?? NoteLayoutMode.card;
    return NoteState(
      roots: roots,
      flatNotes: notes,
      selectedNode: selected,
      layoutMode: currentMode,
      cardIndex: cardIndex,
    );
  }

  void _updateState(NoteState Function(NoteState) updater) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(updater(current));
    }
  }

  // ── 创建 ────────────────────────────────────────────────
  Future<NoteTreeNode?> createNote({
    required String name,
    int? parentId,
    int level = 0,
  }) async {
    final entity = await _repo.create(
      name: name,
      type: 'note',
      parentId: parentId,
      level: level,
    );
    final newNode = NoteTreeNode.fromEntity(entity);
    final current = state.value;
    state = AsyncData(
      _loadState(current?.layoutMode, newNode, current?.cardIndex ?? 0),
    );
    return newNode;
  }

  Future<NoteTreeNode?> createFolder({
    required String name,
    int? parentId,
    int level = 0,
  }) async {
    final entity = await _repo.create(
      name: name,
      type: 'folder',
      parentId: parentId,
      level: level,
    );
    final current = state.value;
    state = AsyncData(
      _loadState(
        current?.layoutMode,
        current?.selectedNode,
        current?.cardIndex ?? 0,
      ),
    );
    return NoteTreeNode.fromEntity(entity);
  }

  // ── 内容保存（5s 自动保存调用此方法）──────────────────
  Future<void> saveContent(int id, String deltaJson) async {
    await _repo.updateContent(id, deltaJson);
    // 更新内存中的节点（避免全量重建树）
    _updateState((s) {
      final node = _findNode(s.roots, id);
      if (node != null) node.content = deltaJson;
      return s;
    });
  }

  // ── 重命名 ──────────────────────────────────────────────
  Future<void> renameNode(int id, String newName) async {
    await _repo.updateName(id, newName);
    final current = state.value;
    state = AsyncData(
      _loadState(
        current?.layoutMode,
        current?.selectedNode,
        current?.cardIndex ?? 0,
      ),
    );
  }

  // ── 删除 ────────────────────────────────────────────────
  Future<void> deleteNode(int id) async {
    await _repo.deleteById(id);
    final current = state.value;
    final wasSelected = current?.selectedNode?.id == id;
    state = AsyncData(
      _loadState(
        current?.layoutMode,
        wasSelected ? null : current?.selectedNode,
        current?.cardIndex ?? 0,
      ),
    );
  }

  // ── 移动（拖拽）────────────────────────────────────────
  Future<void> moveNode(int nodeId, int? newParentId, int newLevel) async {
    await _repo.updateParent(nodeId, newParentId, newLevel);
    final current = state.value;
    state = AsyncData(
      _loadState(
        current?.layoutMode,
        current?.selectedNode,
        current?.cardIndex ?? 0,
      ),
    );
  }

  // ── 选中节点 ────────────────────────────────────────────
  void selectNode(NoteTreeNode node) {
    _updateState((s) => s.copyWith(selectedNode: node));
  }

  // ── 布局切换 ────────────────────────────────────────────
  void setLayoutMode(NoteLayoutMode mode) {
    _updateState((s) => s.copyWith(layoutMode: mode));
  }

  // ── Card 索引 ────────────────────────────────────────────
  void setCardIndex(int index) {
    _updateState((s) {
      final notes = s.flatNotes;
      final selected = index < notes.length ? notes[index] : null;
      return s.copyWith(cardIndex: index, selectedNode: selected);
    });
  }

  // ── 工具方法 ────────────────────────────────────────────
  NoteTreeNode? _findNode(List<NoteTreeNode> nodes, int id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(n.children, id);
      if (found != null) return found;
    }
    return null;
  }
}
