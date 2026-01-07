class UserInfo {
  /// 用户ID
  final int userId;

  /// 用户账号（登录名称）
  final String userName;

  /// 用户昵称
  final String nickName;

  /// 用户邮箱
  final String email;

  /// 手机号码
  final String phoneNumber;

  /// 用户性别：0=男,1=女,2=未知
  final String sex;

  /// 用户头像
  final String avatar;

  UserInfo({
    required this.userId,
    required this.userName,
    required this.nickName,
    required this.email,
    required this.phoneNumber,
    required this.sex,
    required this.avatar,
  });

  /// JSON 反序列化
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      nickName: json['nickName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phonenumber'] ?? '',
      sex: json['sex'] ?? '2',
      avatar: json['avatar'] ?? '',
    );
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'nickName': nickName,
      'email': email,
      'phonenumber': phoneNumber,
      'sex': sex,
      'avatar': avatar,
    };
  }
}
