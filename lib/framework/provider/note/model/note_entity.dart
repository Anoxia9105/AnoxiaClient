import 'package:hive/hive.dart';

part 'note_entity.g.dart';

@HiveType(typeId: 0)
class NoteEntity extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'folder' | 'note'

  @HiveField(3)
  int? parentId;

  @HiveField(4)
  String content; // Quill delta JSON string

  @HiveField(5)
  String createdAt;

  @HiveField(6)
  String updatedAt;

  @HiveField(7)
  int level;

  @HiveField(8)
  int sort;

  NoteEntity({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    required this.level,
    this.sort = 0,
  });

  NoteEntity copyWith({
    String? name,
    String? type,
    int? parentId,
    String? content,
    String? updatedAt,
    int? level,
    int? sort,
  }) {
    return NoteEntity(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      level: level ?? this.level,
      sort: sort ?? this.sort,
    );
  }
}
