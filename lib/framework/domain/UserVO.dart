/// 用户视图对象
///
/// 用于展示用户的精简信息，包含登录信息和基础资料。
class UserVO {
  /// 用户ID
  final int userId;

  /// 用户账号（登录名）
  final String userName;

  /// 昵称
  final String nickName;

  /// 电子邮箱
  final String? email;

  /// 手机号码
  final String? phonenumber;

  /// 性别：0=男，1=女，2=未知
  final String? sex;

  /// 头像 URL
  final String? avatar;

  /// 账号状态
  final String? status;

  /// 最后登录 IP
  final String? loginIp;

  /// 最后登录时间
  final String? loginDate;

  /// 是否为管理员
  final bool? admin;

  UserVO({
    required this.userId,
    required this.userName,
    required this.nickName,
    this.email,
    this.phonenumber,
    this.sex,
    this.avatar,
    this.status,
    this.loginIp,
    this.loginDate,
    this.admin,
  });

  /// 从 JSON 数据构造 [UserVO] 实例
  factory UserVO.fromJson(Map<String, dynamic> json) {
    return UserVO(
      userId: json['userId'],
      userName: json['userName'],
      nickName: json['nickName'],
      email: json['email'],
      phonenumber: json['phonenumber'],
      sex: json['sex'],
      avatar: json['avatar'],
      status: json['status'],
      loginIp: json['loginIp'],
      loginDate: json['loginDate'],
      admin: json['admin'],
    );
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'nickName': nickName,
      'email': email,
      'phonenumber': phonenumber,
      'sex': sex,
      'avatar': avatar,
      'status': status,
      'loginIp': loginIp,
      'loginDate': loginDate,
      'admin': admin,
    };
  }
}
