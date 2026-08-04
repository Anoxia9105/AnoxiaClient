/// 本地存储键值常量
///
/// 集中管理应用本地存储（SharedPreferences）的所有键名
class StorageKeys {
  /// 用户访问 Token
  static const String accessToken = 'ACCESS_TOKEN';

  /// 用户信息
  static const String sysUser = 'SYS_USER';

  /// 密钥（用于加密等）
  static const String secret = 'SECRET';

  /// 蓝牙权限是否已申请（布尔值，true/false）
  static const String kBluetoothPermissionRequestedKey =
      'bluetooth_permission_requested_v1';

  /// 上次登录成功用户的 ID（字符串形式的数字）
  ///
  /// 用于自动恢复登录时校验本地会话缓存是否属于当前用户；
  /// 若不一致则先清空本地缓存，避免展示上一个账号的残留数据。
  static const String lastLoginUserId = 'LAST_LOGIN_USER_ID';
}
