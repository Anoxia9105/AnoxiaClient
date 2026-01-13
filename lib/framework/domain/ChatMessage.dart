import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';

class ChatMessage {
  final String? messageId; // 消息ID
  final String? roomId; // 聊天室ID
  final int? senderId; // 发送者用户ID
  final MessageType? messageType; // 消息类型
  final String content; // 消息预览内容  【----】
  final MessagePayload? payload; // 富文本/详情
  final List<Attachment> attachments; // 附件列表
  final Map<String, dynamic> extra; // 扩展字段
  final MessageState? messageStatus; // 消息状态
  final int? timestamp; // 发送时间戳
  final int? seq; // 序列号 (用于插值计算)

  ChatMessage({
    this.messageId,
    this.roomId,
    this.senderId,
    this.messageType,
    this.payload,
    this.messageStatus,
    this.timestamp,
    this.seq,
    this.content = '',
    this.attachments = const [],
    this.extra = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId']?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId'] != null ? int.tryParse(json['senderId'].toString()) : null,
      messageType: MessageType.fromCode(json["messageType"] ?? 5),
      content: json['content']?.toString() ?? '',
      payload: json['payload'] != null ? MessagePayload.fromJson(json['payload']) : null,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e))
          .toList() ??
          [],
      extra: (json['extra'] as Map<String, dynamic>?) ?? {},
      messageStatus: MessageState.from(json['messageStatus']),
      timestamp: json['timestamp'] != null ? int.tryParse(json['timestamp'].toString()) : null,
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }
}
