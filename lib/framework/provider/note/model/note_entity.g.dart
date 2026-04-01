// GENERATED CODE - DO NOT MODIFY BY HAND
// 手动编写的 Hive 适配器，等同于 build_runner 生成的结果

part of 'note_entity.dart';

class NoteEntityAdapter extends TypeAdapter<NoteEntity> {
  @override
  final int typeId = 0;

  @override
  NoteEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteEntity(
      id: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as String,
      parentId: fields[3] as int?,
      content: (fields[4] as String?) ?? '',
      createdAt: fields[5] as String,
      updatedAt: fields[6] as String,
      level: fields[7] as int,
      sort: (fields[8] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, NoteEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.level)
      ..writeByte(8)
      ..write(obj.sort);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
