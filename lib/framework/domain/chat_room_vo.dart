import 'chat_message.dart';

/// 聊天室类型枚举
enum RoomType {
  singleChat, // 单聊
  groupChat, // 群聊
  aiChat, // AI 对话
  official, // 官方虚拟房间（纯前端展示，不支持聊天/通话）
}

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
  final int? joinPolicy;

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

  /// 成员级免打扰（来自服务端成员设置）
  ///
  /// null 表示服务端未提供该字段（旧部署/未查询），客户端应回落本地缓存行为。
  final bool? isMuted;

  /// 成员级置顶（来自服务端成员设置）
  ///
  /// null 表示服务端未提供该字段（旧部署/未查询），客户端应回落本地缓存行为。
  final bool? isPinned;
  final int? hiddenAtSeq;

  bool get isHidden =>
      hiddenAtSeq != null && (lastMessage?.seq ?? 0) <= hiddenAtSeq!;

  /// 是否为官方虚拟房间（纯前端展示，不支持聊天/通话/成员管理）
  bool get isOfficial => roomType == RoomType.official.index;

  ChatRoomVO({
    this.roomId,
    this.roomName,
    this.roomAvatar,
    this.roomDescription,
    this.roomStatus,
    this.roomType,
    this.joinPolicy,
    this.createdAt,
    this.lastReadSeq,
    this.peerId,
    this.unreadCount,
    this.lastMessage,
    this.isOpenSearch,
    this.isMuted,
    this.isPinned,
    this.hiddenAtSeq,
  });

  /// 创建当前实例的变体副本
  ChatRoomVO copyWith({
    String? roomId,
    String? roomName,
    String? roomAvatar,
    String? roomDescription,
    int? roomStatus,
    int? roomType,
    int? joinPolicy,
    DateTime? createdAt,
    int? lastReadSeq,
    int? peerId,
    int? unreadCount,
    ChatMessage? lastMessage,
    bool? isOpenSearch,
    bool? isMuted,
    bool? isPinned,
    int? hiddenAtSeq,
  }) {
    return ChatRoomVO(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      roomAvatar: roomAvatar ?? this.roomAvatar,
      roomDescription: roomDescription ?? this.roomDescription,
      roomStatus: roomStatus ?? this.roomStatus,
      roomType: roomType ?? this.roomType,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      createdAt: createdAt ?? this.createdAt,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
      peerId: peerId ?? this.peerId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      isOpenSearch: isOpenSearch ?? this.isOpenSearch,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      hiddenAtSeq: hiddenAtSeq ?? this.hiddenAtSeq,
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
      joinPolicy: json['joinPolicy'] is int
          ? json['joinPolicy']
          : int.tryParse(json['joinPolicy']?.toString() ?? ''),
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
      isMuted: _parseFlag(json['isMuted']),
      isPinned: _parseFlag(json['isPinned']),
      hiddenAtSeq: int.tryParse(json['hiddenAtSeq']?.toString() ?? ''),
    );
  }

  /// 解析成员级开关字段（isMuted/isPinned）。
  ///
  /// 服务端序列化为 bool；为兼容兼容网关/中间层会转数字或字符串的情况，
  /// 同时接受 1/0 与 'true'/'false'。缺省/无法识别返回 null（回落本地）。
  static bool? _parseFlag(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }
}
