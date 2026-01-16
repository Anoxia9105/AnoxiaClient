/// 聊天联系人 视图对象
class ChatContactVO {
  /// 联系人ID
  final int? contactId;
  /// 备注
  final String? remark;
  /// 昵称
  final String? nickName;
  /// 头像
  final String? avatar;
  /// 性别
  final String? sex;
  /// 用户在线状态：true=在线 false=离线
  final bool? onlineStatus;

  ChatContactVO({
    this.contactId,
    this.remark,
    this.nickName,
    this.avatar,
    this.sex,
    this.onlineStatus,
  });

  // 从 JSON 构造对象
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

  // 转换为 JSON
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
}