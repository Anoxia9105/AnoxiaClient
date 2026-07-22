class GroupManagerPreview {
  final String name;
  final String? avatar;
  final int roleId;
  const GroupManagerPreview({
    required this.name,
    this.avatar,
    required this.roleId,
  });
  factory GroupManagerPreview.fromJson(Map<String, dynamic> json) =>
      GroupManagerPreview(
        name: json['nickName']?.toString() ?? '',
        avatar: json['avatar']?.toString(),
        roleId: int.tryParse(json['roleId']?.toString() ?? '') ?? 1,
      );
}

class GroupPreview {
  final String roomId;
  final String name;
  final String? avatar;
  final String description;
  final int status;
  final int joinPolicy;
  final int memberCount;
  final bool member;
  final bool pendingRequest;
  final bool joinable;
  final List<GroupManagerPreview> managers;
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
