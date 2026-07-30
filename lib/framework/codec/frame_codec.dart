import 'dart:typed_data';

/// IM V5 应用层二进制帧编解码器
///
/// 帧格式（8 字节头 + Body）：
/// +---------------+---------------+---------------+---------------+
/// |  Magic (2B)   |  Version (1B) |  OpCode (1B)  |  Length (4B)  |
/// +---------------+---------------+---------------+---------------+
/// | Body (protobuf PacketEnvelopeV5) ...                          |
/// +---------------------------------------------------------------+
class FrameCodec {
  static const int magic = 0xA110;
  static const int version = 5;

  /// Ping 帧（客户端心跳）
  static const int opPing = 0x01;

  /// Pong 帧（服务端心跳响应）
  static const int opPong = 0x02;

  /// Protobuf 业务数据帧
  static const int opProtobuf = 0x10;

  static const int headerLength = 8;

  // ─── 编码 ────────────────────────────────────────────────────────────────

  /// 构建 Ping 帧（无 Body）
  static Uint8List buildPing() => _buildFrame(opPing, Uint8List(0));

  /// 构建 Pong 帧（无 Body）
  static Uint8List buildPong() => _buildFrame(opPong, Uint8List(0));

  /// 构建 Protobuf 业务帧
  static Uint8List buildProtobuf(Uint8List body) =>
      _buildFrame(opProtobuf, body);

  // ─── 解码 ────────────────────────────────────────────────────────────────

  /// 解析二进制帧，返回 [FrameResult]；格式非法时抛 [FormatException]
  static FrameResult parse(Uint8List data) {
    if (data.length < headerLength) {
      throw FormatException('Frame too short: ${data.length}');
    }
    final view = ByteData.sublistView(data);

    final m = view.getUint16(0, Endian.big);
    if (m != magic) {
      throw FormatException('Invalid magic: 0x${m.toRadixString(16)}');
    }

    final v = view.getUint8(2);
    if (v != version) {
      throw FormatException('Unsupported version: $v');
    }

    final opCode = view.getUint8(3);
    final length = view.getUint32(4, Endian.big);

    if (data.length < headerLength + length) {
      throw FormatException(
        'Frame body truncated: expected $length, available ${data.length - headerLength}',
      );
    }

    final body = Uint8List.sublistView(data, headerLength, headerLength + length);
    return FrameResult(opCode, body);
  }

  // ─── 内部 ────────────────────────────────────────────────────────────────

  static Uint8List _buildFrame(int opCode, Uint8List body) {
    final buf = Uint8List(headerLength + body.length);
    final view = ByteData.sublistView(buf);
    view.setUint16(0, magic, Endian.big);
    view.setUint8(2, version);
    view.setUint8(3, opCode);
    view.setUint32(4, body.length, Endian.big);
    if (body.isNotEmpty) {
      buf.setRange(headerLength, headerLength + body.length, body);
    }
    return buf;
  }
}

/// 帧解析结果
class FrameResult {
  final int opCode;
  final Uint8List body;

  const FrameResult(this.opCode, this.body);

  bool get isPing => opCode == FrameCodec.opPing;
  bool get isPong => opCode == FrameCodec.opPong;
  bool get isProtobuf => opCode == FrameCodec.opProtobuf;
}
