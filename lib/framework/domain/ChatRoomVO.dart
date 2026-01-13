import 'ChatMessage.dart';

class ChatRoomVO {
  final String? roomId; // 聊天室ID
  final String? roomName; // 聊天室名称
  final String? roomAvatar; // 聊天室头像
  final String? roomDescription; // 聊天室描述
  final int? roomStatus; // 聊天室状态:0-NORMAL，1-MUTED，2-BLOCKED，3-DELETED
  final String? roomType; // 聊天室类型:0-SINGLE，1-GROUP，2-AI
  final DateTime? createdAt; // 创建时间
  final String? lastReadSeq; // 水位线
  final int? peerId; // 对方用户ID (单聊时有值)

  final int? unreadCount; // 未读数 (来自Redis)
  final ChatMessage? lastMessage; // 最后一条消息 (来自Redis)



  ChatRoomVO({
    this.roomId,
    this.roomName,
    this.roomAvatar,
    this.roomDescription,
    this.roomStatus,
    this.roomType,
    this.createdAt,
    this.lastReadSeq,
    this.peerId,
    this.unreadCount,
    this.lastMessage,
  });

  ChatRoomVO copyWith({
    String? roomId,
    String? roomName,
    String? roomAvatar,
    String? roomDescription,
    int? roomStatus,
    String? roomType,
    DateTime? createdAt,
    String? lastReadSeq,
    int? peerId,
    int? unreadCount,
    ChatMessage? lastMessage,
  }) {
    return ChatRoomVO(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      roomAvatar: roomAvatar ?? this.roomAvatar,
      roomDescription: roomDescription ?? this.roomDescription,
      roomStatus: roomStatus ?? this.roomStatus,
      roomType: roomType ?? this.roomType,
      createdAt: createdAt ?? this.createdAt,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
      peerId: peerId ?? this.peerId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }


  factory ChatRoomVO.fromJson(Map<String, dynamic> json) {
    return ChatRoomVO(
      roomId: json['roomId']?.toString(),
      roomName: json['roomName'],
      roomAvatar: json['roomAvatar'],
      roomDescription: json['roomDescription'],
      roomStatus: json['roomStatus'] is int ? json['roomStatus'] : int.tryParse(json['roomStatus']?.toString() ?? ''),
      roomType: json['roomType']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      lastReadSeq: json['lastReadSeq']?.toString(),
      peerId: json['peerId'] != null ? int.tryParse(json['peerId'].toString()) : null,
      unreadCount: json['unreadCount'] != null ? int.tryParse(json['unreadCount'].toString()) : 0,
      lastMessage: json['lastMessage'] != null ? ChatMessage.fromJson(json['lastMessage']) : null,
    );
  }



}