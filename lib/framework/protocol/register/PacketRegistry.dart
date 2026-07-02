import 'dart:typed_data';

import '../IPacket.dart';
import '../PacketType.dart';

/// 二进制数据包解析器类型定义（V5 协议）
typedef BinaryPacketParser = IPacket? Function(Uint8List payload, int codecId);

/// 数据包解析注册表（V5 二进制协议版）
///
/// 维护 [PacketType] → 解析器的映射，
/// 根据消息主题动态选择正确的解析逻辑。
class PacketRegistry {
  PacketRegistry._();

  static final Map<PacketType, BinaryPacketParser> _parsers = {};

  /// 注册二进制解析器
  static void register(PacketType type, BinaryPacketParser parser) {
    _parsers[type] = parser;
  }

  /// 解析消息（V5 二进制格式）
  static IPacket? parse(PacketType type, Uint8List payload, int codecId) {
    final parser = _parsers[type];
    if (parser == null) return null;
    return parser(payload, codecId);
  }
}
