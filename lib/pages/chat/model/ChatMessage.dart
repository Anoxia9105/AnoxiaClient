/// 聊天消息数据模型
class ChatMessage {
  /// 消息ID（使用时间戳）
  final String id;

  /// 发送者ID
  final String senderId;

  /// 发送者名称
  final String senderName;

  /// 消息内容
  final String content;

  /// 发送时间
  final DateTime timestamp;

  /// 是否是本地消息
  final bool isLocal;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isLocal = false,
  });

  /// 从JSON反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : (json['timestamp'] as DateTime? ?? DateTime.now()),
      isLocal: json['isLocal'] as bool? ?? false,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isLocal': isLocal,
    };
  }

  /// 复制方法
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isLocal,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  String toString() => 'ChatMessage(id: $id, sender: $senderName, content: $content)';
}
