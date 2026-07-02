import 'dart:convert';
import 'dart:typed_data';

/// 轻量级 Protobuf 二进制编码器（仅支持 IM V5 协议所需字段类型）
///
/// 支持的字段类型：
/// - uint32 / int32 / int64 → varint (wire type 0)
/// - bool                   → varint (wire type 0)
/// - string                 → length-delimited (wire type 2)
/// - bytes                  → length-delimited (wire type 2)
/// - embedded message       → length-delimited (wire type 2)
/// - repeated int64         → 逐条 varint
/// - repeated message       → 逐条 length-delimited
class ProtoWriter {
  final List<int> _buf = [];

  // ─── uint32 ──────────────────────────────────────────────────────────────

  void writeUint32(int fieldNum, int value) {
    if (value == 0) return;
    _writeTag(fieldNum, 0);
    _writeVarint(value);
  }

  // ─── int32 ───────────────────────────────────────────────────────────────

  void writeInt32(int fieldNum, int value) {
    if (value == 0) return;
    _writeTag(fieldNum, 0);
    _writeVarint(value);
  }

  // ─── int64 ───────────────────────────────────────────────────────────────

  void writeInt64(int fieldNum, int value) {
    if (value == 0) return;
    _writeTag(fieldNum, 0);
    _writeVarint(value);
  }

  // ─── bool ────────────────────────────────────────────────────────────────

  void writeBool(int fieldNum, bool value) {
    if (!value) return;
    _writeTag(fieldNum, 0);
    _writeVarint(1);
  }

  // ─── string ──────────────────────────────────────────────────────────────

  void writeString(int fieldNum, String? value) {
    if (value == null || value.isEmpty) return;
    final bytes = utf8.encode(value);
    _writeTag(fieldNum, 2);
    _writeVarint(bytes.length);
    _buf.addAll(bytes);
  }

  // ─── bytes ───────────────────────────────────────────────────────────────

  void writeBytes(int fieldNum, Uint8List? value) {
    if (value == null || value.isEmpty) return;
    _writeTag(fieldNum, 2);
    _writeVarint(value.length);
    _buf.addAll(value);
  }

  // ─── embedded message ────────────────────────────────────────────────────

  void writeMessage(int fieldNum, ProtoWriter nested) {
    final bytes = nested.toBytes();
    if (bytes.isEmpty) return;
    _writeTag(fieldNum, 2);
    _writeVarint(bytes.length);
    _buf.addAll(bytes);
  }

  // ─── repeated int64 ──────────────────────────────────────────────────────

  void writeRepeatedInt64(int fieldNum, List<int> values) {
    for (final v in values) {
      writeInt64(fieldNum, v);
    }
  }

  // ─── output ──────────────────────────────────────────────────────────────

  Uint8List toBytes() => Uint8List.fromList(_buf);

  bool get isEmpty => _buf.isEmpty;

  // ─── internals ───────────────────────────────────────────────────────────

  void _writeTag(int fieldNum, int wireType) {
    _writeVarint((fieldNum << 3) | wireType);
  }

  /// 通用 varint 编码（支持有符号 64 位 — 使用无符号右移避免符号扩展）
  void _writeVarint(int value) {
    while (true) {
      // 检查是否还有超出低 7 位的数据
      if ((value & ~0x7F) == 0) {
        _buf.add(value & 0xFF);
        return;
      }
      _buf.add((value & 0x7F) | 0x80);
      value = value >>> 7; // 无符号右移，保证负数正确编码为 10 字节
    }
  }
}
