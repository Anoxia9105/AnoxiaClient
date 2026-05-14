import '../IPacket.dart';
import '../PacketType.dart';

/// 消息解析器类型定义
///
/// 接收 JSON Map，返回对应的 [IPacket] 实例
typedef PacketParser = IPacket Function(Map<String, dynamic> data);

/// 数据包解析注册表
///
/// 维护 [PacketType] 到解析器的映射，
/// 用于根据消息主题动态选择正确的解析逻辑。
class PacketRegistry {
  PacketRegistry._();

  /// 解析器注册表
  static final Map<PacketType, PacketParser> _parsers = {};

  /// 注册解析器
  ///
  /// 在应用启动时调用，将消息类型与解析器关联
  static void register(PacketType type, PacketParser parser) {
    _parsers[type] = parser;
  }

  /// 解析消息
  ///
  /// 根据 [type] 查找对应解析器并执行解析
  static IPacket? parse(PacketType type, Map<String, dynamic> data) {
    final parser = _parsers[type];
    if (parser == null) return null;
    return parser(data);
  }
}
