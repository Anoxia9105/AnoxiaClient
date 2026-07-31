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

  // ─── double ───────────────────────────────────────────────────────────────

  void writeDouble(int fieldNum, double? value) {
    if (value == null) return;
    final data = ByteData(8)..setFloat64(0, value, Endian.little);
    _writeTag(fieldNum, 1);
    _buf.addAll(data.buffer.asUint8List());
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

  /// 通用 varint 编码（支持有符号 64 位 —— 使用 BigInt 保证跨平台一致）。
  ///
  /// ⚠️ dart2js 下 `>>>` / `>>` 为 32 位语义：原实现 `value >>> 7` 会把 clientTimestamp
  /// (~1.75e12，约 41 位) 这类大于 2^32 的值截断成垃圾，导致对方/UI 拿到错乱时间戳。
  /// 改用 BigInt.toUnsigned(64) 做真正的无符号 64 位右移。
  void _writeVarint(int value) {
    BigInt v = BigInt.from(value).toUnsigned(64);
    while (true) {
      final int chunk = (v & BigInt.from(0x7F)).toInt();
      v = v >> 7;
      if (v == BigInt.zero) {
        _buf.add(chunk & 0xFF);
        return;
      }
      _buf.add((chunk | 0x80) & 0xFF);
    }
  }
}
