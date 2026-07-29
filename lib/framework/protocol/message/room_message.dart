import '../i_packet.dart';
import 'message_eunm.dart';
import 'message_payload.dart';
import 'package:flutter/foundation.dart';

/// 聊天室消息（V5 协议对齐）
///
/// 该类表示一条完整的聊天室消息，与服务端 `RoomMessageProtoV5` 协议结构保持一致。
/// V5 协议移除了 `senderName`、`senderAvatar`、`targetId`、`state`、`status` 等字段，
/// 因为这些属于业务展示层数据，不在协议层传输，由上层自行管理。
///
/// 所有字段均为不可变（immutable），保证线程安全和状态可预测性。
@immutable
class RoomMessage implements IPacket {
  // ==================== 字段 ====================

  /// 服务端生成的消息唯一标识符（全局唯一）
  final String messageId;

  /// 客户端生成的消息临时标识符，用于去重和确认（可选）
  final String? clientMsgId;

  /// 所属聊天室 ID
  final String roomId;

  /// 发送者用户 ID
  final int senderId;

  /// 消息类型（文本、图片、语音、自定义等）
  final MessageType messageType;

  /// 消息具体内容载荷，根据 [messageType] 解析不同类型的数据
  final MessagePayload? payload;

  /// 扩展属性键值对，用于传递附加信息（如 @ 成员、引用消息等）
  final Map<String, String> properties;

  /// 消息在聊天室中的顺序号，由服务端分配，单调递增
  final int? seq;

  /// 服务端时间戳（毫秒）
  final int? serverTimestamp;

  /// 客户端本地时间戳（毫秒），由发送端生成
  final int? clientTimestamp;

  // ==================== 构造函数 ====================

  /// 构造 [RoomMessage] 实例。
  /// 所有参数均为必填，但部分可为空（如 `clientMsgId`、`payload`）。
  const RoomMessage({
    required this.messageId,
    this.clientMsgId,
    required this.roomId,
    required this.senderId,
    required this.messageType,
    this.payload,
    this.properties = const {},
    this.seq,
    this.serverTimestamp,
    this.clientTimestamp,
  });

  // ==================== 辅助属性 ====================

  /// 获取消息的有效时间戳。
  /// 优先使用服务端时间戳，若为空则回退到客户端时间戳，再为空则返回 0。
  int get timestamp => serverTimestamp ?? clientTimestamp ?? 0;

  // ==================== 序列化 ====================

  /// 将消息对象转换为 JSON Map，用于网络传输或持久化。
  @override
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'clientMsgId': clientMsgId,
    'roomId': roomId,
    'senderId': senderId,
    'messageType': MessageType.toCode(messageType),
    'payload': payload?.toTypedJson(messageType),
    'properties': properties,
    'seq': seq,
    'serverTimestamp': serverTimestamp,
    'clientTimestamp': clientTimestamp,
  };

  // ==================== 复制方法 ====================

  /// 创建当前消息的副本，并可选择性更新部分字段。
  /// 常用于修改消息状态（如更新已读、撤回等）而不破坏不可变性。
  RoomMessage copyWith({
    String? messageId,
    String? clientMsgId,
    String? roomId,
    int? senderId,
    MessageType? messageType,
    MessagePayload? payload,
    Map<String, String>? properties,
    int? seq,
    int? serverTimestamp,
    int? clientTimestamp,
  }) => RoomMessage(
    messageId: messageId ?? this.messageId,
    clientMsgId: clientMsgId ?? this.clientMsgId,
    roomId: roomId ?? this.roomId,
    senderId: senderId ?? this.senderId,
    messageType: messageType ?? this.messageType,
    payload: payload ?? this.payload,
    properties: properties ?? this.properties,
    seq: seq ?? this.seq,
    serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    clientTimestamp: clientTimestamp ?? this.clientTimestamp,
  );

  // ==================== 相等性与哈希 ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomMessage &&
        other.messageId == messageId &&
        other.clientMsgId == clientMsgId &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.messageType == messageType &&
        other.seq == seq &&
        other.serverTimestamp == serverTimestamp;
  }

  @override
  int get hashCode =>
      messageId.hashCode ^
      clientMsgId.hashCode ^
      roomId.hashCode ^
      senderId.hashCode ^
      messageType.hashCode ^
      seq.hashCode;

  // ==================== 字符串表示 ====================

  /// 返回消息的字符串表示，便于调试和日志输出。
  /// 包含所有关键字段，payload 仅显示类型信息以避免输出过长内容。
  @override
  String toString() {
    return 'RoomMessage{'
        'messageId: $messageId, '
        'clientMsgId: $clientMsgId, '
        'roomId: $roomId, '
        'senderId: $senderId, '
        'messageType: ${MessageType.toCode(messageType)}, '
        'payload: ${payload?.runtimeType ?? 'null'}, '
        'properties: $properties, '
        'seq: $seq, '
        'serverTimestamp: $serverTimestamp, '
        'clientTimestamp: $clientTimestamp'
        '}';
  }
}