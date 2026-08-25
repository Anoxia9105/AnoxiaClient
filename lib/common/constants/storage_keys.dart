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

  /// 已登录账号列表（JSON 数组，见 [SavedAccount]）
  ///
  /// 「切换账号」功能的数据源：保存登录成功过的账号摘要与各自 token，
  /// 上限 [SavedAccountsService.maxAccounts] 个，超出淘汰最久未用的。
  static const String savedAccounts = 'SAVED_ACCOUNTS';

  /// 是否隐藏官方虚拟房间（布尔值，true=隐藏）
  static const String officialRoomHidden = 'OFFICIAL_ROOM_HIDDEN';

  /// AI 会话 ID（按用户隔离，key 前缀 + userId）
  ///
  /// 用于持久化 `/chat/ai/stream` 返回的 `conversationId`，实现多轮记忆。
  /// 客户端在 done 事件中保存，下次请求时回传。
  static const String aiConversationIdPrefix = 'AI_CONVERSATION_ID_';

  /// 获取当前用户的 AI 会话持久化 key
  static String aiConversationIdKey(String userId) =>
      '$aiConversationIdPrefix$userId';
}
