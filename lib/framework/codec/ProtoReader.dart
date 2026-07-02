import 'dart:convert';
import 'dart:typed_data';

/// 轻量级 Protobuf 二进制解码器
///
/// 一次性读取所有字段到 Map，字段值类型：
/// - wire 0 → int (varint)
/// - wire 2 → Uint8List (raw bytes)
/// - 重复字段 → List<dynamic>（同一 fieldNum 出现多次时自动升级为 List）
class ProtoReader {
  final Uint8List _data;
  int _pos;

  ProtoReader(this._data) : _pos = 0;
  ProtoReader.view(Uint8List data, int offset, int length)
      : _data = data,
        _pos = offset;

  bool get hasMore => _pos < _data.length;

  /// 读取所有字段，返回 {fieldNum: value|List} 映射
  Map<int, dynamic> readAll() {
    final result = <int, dynamic>{};
    while (hasMore) {
      final tag = _readVarint();
      final fieldNum = tag >> 3;
      final wireType = tag & 0x7;
      switch (wireType) {
        case 0: // varint
          final value = _readVarint();
          _addToMap(result, fieldNum, value);
        case 2: // length-delimited
          final len = _readVarint();
          if (_pos + len > _data.length) {
            throw FormatException(
              'Length-delimited field truncated: len=$len, pos=$_pos, size=${_data.length}',
            );
          }
          final bytes = Uint8List.view(
            _data.buffer,
            _data.offsetInBytes + _pos,
            len,
          );
          _pos += len;
          _addToMap(result, fieldNum, Uint8List.fromList(bytes));
        case 1: // 64-bit fixed — 跳过
          _pos += 8;
        case 5: // 32-bit fixed — 跳过
          _pos += 4;
        default:
          throw FormatException('Unknown wire type: $wireType at pos $_pos');
      }
    }
    return result;
  }

  void _addToMap(Map<int, dynamic> map, int fieldNum, dynamic value) {
    if (map.containsKey(fieldNum)) {
      final existing = map[fieldNum];
      if (existing is List) {
        existing.add(value);
      } else {
        map[fieldNum] = [existing, value];
      }
    } else {
      map[fieldNum] = value;
    }
  }

  int _readVarint() {
    int result = 0;
    int shift = 0;
    while (_pos < _data.length) {
      final b = _data[_pos++];
      result |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }
}

// ─── 便利扩展方法 ─────────────────────────────────────────────────────────────

extension ProtoMapHelpers on Map<int, dynamic> {
  /// 读取 uint32 / enum 字段（默认 0）
  int getUint32(int fieldNum) {
    final v = this[fieldNum];
    if (v is int) return v;
    return 0;
  }

  /// 读取 int64 字段（默认 0）
  int getInt64(int fieldNum) {
    final v = this[fieldNum];
    if (v is int) return v;
    return 0;
  }

  /// 读取 int32 字段（默认 0）
  int getInt32(int fieldNum) => getUint32(fieldNum);

  /// 读取 bool 字段（默认 false）
  bool getBool(int fieldNum) => getUint32(fieldNum) != 0;

  /// 读取 string 字段（默认空串）
  String getString(int fieldNum) {
    final v = this[fieldNum];
    if (v is Uint8List) return utf8.decode(v, allowMalformed: true);
    return '';
  }

  /// 读取 bytes 字段（默认空）
  Uint8List getBytes(int fieldNum) {
    final v = this[fieldNum];
    if (v is Uint8List) return v;
    return Uint8List(0);
  }

  /// 读取 repeated int64 字段
  List<int> getRepeatedInt64(int fieldNum) {
    final v = this[fieldNum];
    if (v == null) return const [];
    if (v is int) return [v];
    if (v is List) return v.whereType<int>().toList();
    return const [];
  }

  /// 读取 repeated bytes（重复的嵌套消息）
  List<Uint8List> getRepeatedBytes(int fieldNum) {
    final v = this[fieldNum];
    if (v == null) return const [];
    if (v is Uint8List) return [v];
    if (v is List) return v.whereType<Uint8List>().toList();
    return const [];
  }

  /// 读取嵌套消息的字段 Map（length-delimited → 再次解析）
  Map<int, dynamic>? getNestedMap(int fieldNum) {
    final bytes = this[fieldNum];
    if (bytes is! Uint8List || bytes.isEmpty) return null;
    return ProtoReader(bytes).readAll();
  }
}
