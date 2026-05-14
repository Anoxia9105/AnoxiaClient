import 'IPacket.dart';
import 'PacketType.dart';

/// WebSocket 数据包帧
///
/// 封装协议的消息主题（topic）和业务数据（data），
/// 用于 WebSocket 通信时的序列化和反序列化。
///
/// [T] 为 data 的具体类型，需实现 [IPacket] 接口
class PacketFrame<T extends IPacket> {
  /// 消息主题/类型
  final PacketType topic;

  /// 消息业务数据
  final T data;

  PacketFrame({
    required this.topic,
    required this.data,
  });

  /// 从 JSON 构造 [PacketFrame] 实例
  ///
  /// [fromDataJson] 回调函数用于解析 data 部分的具体类型
  factory PacketFrame.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromDataJson,
  ) {
    return PacketFrame(
      // 自动兼容后端传来的数字下标或字符串名称
      topic: PacketType.from(json['topic']),
      data: fromDataJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// 序列化为 JSON
  ///
  /// topic 序列化为数字 index 传给后端
  Map<String, dynamic> toJson() => {
        'topic': topic.index,
        'data': data.toJson(),
      };
}
