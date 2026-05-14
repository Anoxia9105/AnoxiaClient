import 'ChatMessage.dart';

/// 聊天室视图对象
///
/// 表示单个聊天会话/房间的完整信息，包含房间配置、最后消息和未读计数。
class ChatRoomVO {
  /// 聊天室唯一标识
  final String? roomId;

  /// 聊天室名称
  final String? roomName;

  /// 聊天室头像 URL
  final String? roomAvatar;

  /// 聊天室描述/公告
  final String? roomDescription;

  /// 聊天室状态：0=正常，1=全员禁言，2=封禁，3=已删除
  final int? roomStatus;

  /// 聊天室类型：0=单聊，1=群聊，2=AI 对话
  final int? roomType;

  /// 创建时间
  final DateTime? createdAt;

  /// 已读水印（用于消息同步和未读数计算）
  final int? lastReadSeq;

  /// 对方用户ID（仅单聊时有值）
  final int? peerId;

  /// 未读消息数（来自 Redis 缓存）
  final int? unreadCount;

  /// 最后一条消息（来自 Redis 缓存）
  final ChatMessage? lastMessage;

  /// 是否展开搜索栏
  final bool? isOpenSearch;

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
    this.isOpenSearch,
  });

  /// 创建当前实例的变体副本
  ChatRoomVO copyWith({
    String? roomId,
    String? roomName,
    String? roomAvatar,
    String? roomDescription,
    int? roomStatus,
    int? roomType,
    DateTime? createdAt,
    int? lastReadSeq,
    int? peerId,
    int? unreadCount,
    ChatMessage? lastMessage,
    bool? isOpenSearch,
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
      isOpenSearch: isOpenSearch ?? this.isOpenSearch,
    );
  }

  /// 从 JSON 数据构造 [ChatRoomVO] 实例
  ///
  /// 自动处理数字字段的多种类型（int 或 String）
  factory ChatRoomVO.fromJson(Map<String, dynamic> json) {
    return ChatRoomVO(
      roomId: json['roomId']?.toString(),
      roomName: json['roomName'],
      roomAvatar: json['roomAvatar'],
      roomDescription: json['roomDescription'],
      roomStatus: json['roomStatus'] is int
          ? json['roomStatus']
          : int.tryParse(json['roomStatus']?.toString() ?? ''),
      roomType: json['roomType'] is int
          ? json['roomType']
          : int.tryParse(json['roomType']?.toString() ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      lastReadSeq: json['lastReadSeq'] != null
          ? int.tryParse(json['lastReadSeq'].toString())
          : null,
      peerId: json['peerId'] != null
          ? int.tryParse(json['peerId'].toString())
          : null,
      unreadCount: json['unreadCount'] != null
          ? int.tryParse(json['unreadCount'].toString())
          : 0,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
    );
  }
}
