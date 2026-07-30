/// 群组预览领域模型
///
/// 定义群组预览相关的数据类，包括群管理员预览和群组预览信息。
/// 群管理员预览信息
class GroupManagerPreview {
  /// 管理员昵称
  final String name;

  /// 管理员头像 URL
  final String? avatar;

  /// 角色 ID
  final int roleId;

  /// 创建群管理员预览实例
  const GroupManagerPreview({
    required this.name,
    this.avatar,
    required this.roleId,
  });

  /// 从 JSON 创建群管理员预览实例
  factory GroupManagerPreview.fromJson(Map<String, dynamic> json) =>
      GroupManagerPreview(
        name: json['nickName']?.toString() ?? '',
        avatar: json['avatar']?.toString(),
        roleId: int.tryParse(json['roleId']?.toString() ?? '') ?? 1,
      );
}

/// 群组预览信息
class GroupPreview {
  /// 房间 ID
  final String roomId;

  /// 群组名称
  final String name;

  /// 群组头像 URL
  final String? avatar;

  /// 群组描述
  final String description;

  /// 群组状态
  final int status;

  /// 加入策略
  final int joinPolicy;

  /// 成员数量
  final int memberCount;

  /// 当前用户是否为成员
  final bool member;

  /// 是否有待处理的加入请求
  final bool pendingRequest;

  /// 是否可加入
  final bool joinable;

  /// 管理员列表
  final List<GroupManagerPreview> managers;

  /// 创建群组预览实例
  const GroupPreview({
    required this.roomId,
    required this.name,
    this.avatar,
    required this.description,
    required this.status,
    required this.joinPolicy,
    required this.memberCount,
    required this.member,
    required this.pendingRequest,
    required this.joinable,
    required this.managers,
  });

  /// 从 JSON 创建群组预览实例
  factory GroupPreview.fromJson(Map<String, dynamic> json) => GroupPreview(
    roomId: json['roomId']?.toString() ?? '',
    name: json['roomName']?.toString() ?? '',
    avatar: json['roomAvatar']?.toString(),
    description: json['roomDescription']?.toString() ?? '',
    status: int.tryParse(json['roomStatus']?.toString() ?? '') ?? -1,
    joinPolicy: int.tryParse(json['joinPolicy']?.toString() ?? '') ?? 1,
    memberCount: int.tryParse(json['memberCount']?.toString() ?? '') ?? 0,
    member: json['member'] == true,
    pendingRequest: json['pendingRequest'] == true,
    joinable: json['joinable'] == true,
    managers: (json['managers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => GroupManagerPreview.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
