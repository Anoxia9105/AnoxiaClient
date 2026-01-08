import '../IPacket.dart';
import '../PacketType.dart';

/// 定义解析函数签名：接收 Map，返回 IPacket 实例
typedef PacketParser = IPacket Function(Map<String, dynamic> data);

class PacketRegistry {
  // 私有构造函数
  PacketRegistry._();

  // 💡 核心注册表：PacketType 对应 解析函数
  static final Map<PacketType, PacketParser> _parsers = {};

  /// 注册解析器
  static void register(PacketType type, PacketParser parser) {
    _parsers[type] = parser;
  }

  /// 获取解析器并解析数据
  static IPacket? parse(PacketType type, Map<String, dynamic> data) {
    final parser = _parsers[type];
    if (parser == null) return null;
    return parser(data);
  }
}