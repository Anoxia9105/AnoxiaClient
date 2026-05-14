/// 数据包接口
///
/// 所有协议层消息模型需实现此接口，
/// 以支持统一的 JSON 序列化操作。
abstract class IPacket {
  /// 将当前实例转换为 JSON Map
  Map<String, dynamic> toJson();
}
