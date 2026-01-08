import 'IPacket.dart';
import 'PacketType.dart';

class PacketFrame<T extends IPacket> {
  final PacketType topic; // 消息主题
  final T data;           // 消息数据

  PacketFrame({
    required this.topic,
    required this.data,
  });

  /// 核心：从 JSON 解析
  /// [json] 是完整的 Map
  /// [fromDataJson] 是一个函数，告诉类如何解析 T
  factory PacketFrame.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromDataJson,
      ) {
    return PacketFrame(
      // 💡 自动处理后端传来的数字下标或字符串
      topic: PacketType.from(json['topic']),
      data: fromDataJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'topic': topic.index, // 序列化为数字 index 传回后端
    'data': data.toJson(),
  };
}