/// 已登录账号（多账号切换列表条目）
///
/// 保存登录成功过的账号摘要与其 token，用于「切换账号」一键免密切回。
/// token 与当前登录态的 [StorageKeys.accessToken] 同级加密存储（SSUtil）；
/// 服务端同一账号允许多 token 并存、无互踢，切换时不吊销旧 token，
/// 超过服务端 TTL（7 天滑动过期）后该条目静默切换失败，降级为重新登录。
class SavedAccount {
  /// 用户 ID
  final int userId;

  /// 登录账号名（用户名或邮箱，用于重新登录时预填）
  final String userName;

  /// 昵称
  final String nickName;

  /// 头像 URL
  final String avatar;

  /// 该账号最近一次登录得到的 Token
  final String token;

  /// 服务端签发的同设备快速登录随机凭据
  final String quickLoginCredential;

  /// 00=管理员，01=普通用户，02=游客用户
  final String userType;

  /// 最近一次登录/切换回该账号的时间（用于 LRU 淘汰与列表排序）
  final DateTime lastUsedAt;

  const SavedAccount({
    required this.userId,
    required this.userName,
    required this.nickName,
    required this.avatar,
    required this.token,
    required this.quickLoginCredential,
    required this.userType,
    required this.lastUsedAt,
  });

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? '',
      nickName: json['nickName'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      token: json['token'] as String? ?? '',
      quickLoginCredential: json['quickLoginCredential'] as String? ?? '',
      userType: json['userType'] as String? ?? '01',
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'nickName': nickName,
        'avatar': avatar,
        'token': token,
        'quickLoginCredential': quickLoginCredential,
        'userType': userType,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  SavedAccount copyWith({
    String? userName,
    String? nickName,
    String? avatar,
    String? token,
    String? quickLoginCredential,
    String? userType,
    DateTime? lastUsedAt,
  }) {
    return SavedAccount(
      userId: userId,
      userName: userName ?? this.userName,
      nickName: nickName ?? this.nickName,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
      quickLoginCredential:
          quickLoginCredential ?? this.quickLoginCredential,
      userType: userType ?? this.userType,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
