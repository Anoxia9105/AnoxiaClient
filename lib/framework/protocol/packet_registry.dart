import 'dart:typed_data';

import 'i_packet.dart';
import 'packet_type.dart';

/// 二进制数据包解析器类型定义（V5 协议）
typedef BinaryPacketParser = IPacket? Function(Uint8List payload, int codecId);

/// 数据包解析注册表（V5 二进制协议版）
///
/// 维护 [PacketType] → 解析器的映射，
/// 根据消息主题动态选择正确的解析逻辑。
class PacketRegistry {
  PacketRegistry._();

  static final Map<PacketType, BinaryPacketParser> _parsers = {};
  static final Map<int, BinaryPacketParser> _codecParsers = {};
  static final Map<int, PacketType> _codecTopics = {};

  /// 注册二进制解析器
  static void register(PacketType type, BinaryPacketParser parser) {
    _parsers[type] = parser;
  }

  static void registerCodec(
    int codecId,
    PacketType type,
    BinaryPacketParser parser,
  ) {
    _codecParsers[codecId] = parser;
    _codecTopics[codecId] = type;
  }

  /// 解析消息（V5 二进制格式）
  static IPacket? parse(PacketType type, Uint8List payload, int codecId) {
    final parser = _codecParsers[codecId] ?? _parsers[type];
    if (parser == null) return null;
    return parser(payload, codecId);
  }

  static PacketType topicForCodecId(int codecId, PacketType fallback) {
    return _codecTopics[codecId] ?? fallback;
  }
}
