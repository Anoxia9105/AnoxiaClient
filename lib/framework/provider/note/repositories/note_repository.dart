import 'package:anoxia/framework/provider/note/model/note_entity.dart';
import 'package:hive/hive.dart';

class NoteRepository {
  static const _boxName = 'notes';
  late Box<NoteEntity> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      // Hive.registerAdapter(NoteEntityAdapter());
    }
    _box = await Hive.openBox<NoteEntity>(_boxName);
  }

  // ── 查询 ──────────────────────────────────────────────
  List<NoteEntity> getAll() => _box.values.toList();

  NoteEntity? getById(int id) => _box.get(id);

  // ── 写入 ──────────────────────────────────────────────
  Future<NoteEntity> create({
    required String name,
    required String type,
    int? parentId,
    int level = 0,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _nextId();
    final sort = _nextSort(parentId);
    final entity = NoteEntity(
      id: id,
      name: name,
      type: type,
      parentId: parentId,
      content: '',
      createdAt: now,
      updatedAt: now,
      level: level,
      sort: sort,
    );
    await _box.put(id, entity);
    return entity;
  }

  Future<void> updateContent(int id, String content) async {
    final entity = _box.get(id);
    if (entity == null) return;
    entity.content = content;
    entity.updatedAt = DateTime.now().toIso8601String();
    await entity.save();
  }

  Future<void> updateName(int id, String name) async {
    final entity = _box.get(id);
    if (entity == null) return;
    entity.name = name;
    entity.updatedAt = DateTime.now().toIso8601String();
    await entity.save();
  }

  Future<void> updateParent(int id, int? newParentId, int newLevel) async {
    final entity = _box.get(id);
    if (entity == null) return;
    entity.parentId = newParentId;
    entity.level = newLevel;
    entity.updatedAt = DateTime.now().toIso8601String();
    await entity.save();
  }

  Future<void> deleteById(int id) async {
    // 递归删除所有子节点
    final children = _box.values.where((e) => e.parentId == id).toList();
    for (final child in children) {
      await deleteById(child.id);
    }
    await _box.delete(id);
  }

  // ── 工具 ──────────────────────────────────────────────
  int _nextId() {
    if (_box.isEmpty) return 1;
    return _box.values.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _nextSort(int? parentId) {
    final siblings = _box.values.where((e) => e.parentId == parentId).toList();
    if (siblings.isEmpty) return 0;
    return siblings.map((e) => e.sort).reduce((a, b) => a > b ? a : b) + 1;
  }
}
