/// 用户信息模型
///
/// 表示当前登录用户或指定用户的完整个人资料。
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

  /// 用户性别：0=男，1=女，2=未知
  final String sex;

  /// 用户头像 URL
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

  /// 从 JSON 数据构造 [UserInfo] 实例
  ///
  /// 兼容后端 Java 字段命名（phonenumber）
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

  /// 将当前实例转换为 JSON 格式
  ///
  /// 注意：序列化时使用 Java 后端期望的 phonenumber 字段名
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
