/// 聊天联系人视图对象
///
/// 表示好友列表中的单个联系人，包含基本信息、在线状态和展示名称。
class ChatContactVO {
  /// 联系人用户ID
  final int? contactId;

  /// 好友备注名（优先用于展示）
  final String? remark;

  /// 用户昵称（备注为空时使用）
  final String? nickName;

  /// 头像 URL
  final String? avatar;

  /// 性别：0=男，1=女，其他=未知
  final String? sex;

  /// 在线状态：true=在线，false=离线
  final bool? onlineStatus;

  ChatContactVO({
    this.contactId,
    this.remark,
    this.nickName,
    this.avatar,
    this.sex,
    this.onlineStatus,
  });

  /// 从 JSON 数据构造 [ChatContactVO] 实例
  factory ChatContactVO.fromJson(Map<String, dynamic> json) {
    return ChatContactVO(
      contactId: json['contactId'],
      remark: json['remark'],
      nickName: json['nickName'],
      avatar: json['avatar'],
      sex: json['sex'],
      onlineStatus: json['onlineStatus'],
    );
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'remark': remark,
      'nickName': nickName,
      'avatar': avatar,
      'sex': sex,
      'onlineStatus': onlineStatus,
    };
  }

  /// 创建当前实例的变体副本
  ///
  /// 支持局部更新，用于响应式状态管理中的最小化更新
  ChatContactVO copyWith({
    bool? onlineStatus,
    String? remark,
    String? avatar,
  }) {
    return ChatContactVO(
      contactId: contactId,
      remark: remark ?? this.remark,
      nickName: nickName,
      avatar: avatar ?? this.avatar,
      sex: sex,
      onlineStatus: onlineStatus ?? this.onlineStatus,
    );
  }
}
