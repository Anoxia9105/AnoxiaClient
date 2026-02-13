/// 用户视图对象
class UserVO {
  /// 用户ID
  final int userId;
  /// 用户名
  final String userName;
  /// 昵称
  final String nickName;
  /// 邮箱
  final String? email;
  /// 手机号
  final String? phonenumber;
  /// 性别
  final String? sex;
  /// 头像
  final String? avatar;
  /// 状态
  final String? status;
  /// 登录IP
  final String? loginIp;
  /// 登录时间
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

  /// 从 JSON 构造对象
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

  /// 转换为 JSON
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
