/// 本地存储键值常量
///
/// 集中管理应用本地存储（SharedPreferences）的所有键名
class StorageKeys {
  /// 摄像头/共享画质、编码偏好与共享声音开关。
  static const String callMediaPreferences = 'CALL_MEDIA_PREFERENCES';
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

  /// 开机自启动（布尔值，true=随系统登录自动启动，仅桌面端生效）
  static const String launchAtStartup = 'LAUNCH_AT_STARTUP';

  /// 开机自启后是否隐藏主窗口（true=仅驻留系统托盘）
  static const String launchAtStartupSilent = 'LAUNCH_AT_STARTUP_SILENT';

  /// 是否隐藏官方虚拟房间（布尔值，true=隐藏）
  static const String officialRoomHidden = 'OFFICIAL_ROOM_HIDDEN';

  /// 自定义强调色（int color value，null 表示跟随预设）
  static const String customAccentColor = 'CUSTOM_ACCENT_COLOR';

  /// 自定义强调色是否启用
  static const String customAccentEnabled = 'CUSTOM_ACCENT_ENABLED';

  /// 窗口关闭行为：true=最小化到托盘，false=直接退出
  static const String windowMinimizeToTray = 'WINDOW_MINIMIZE_TO_TRAY';

  /// 是否减少动效
  static const String reduceMotion = 'REDUCE_MOTION';

  /// 本设备是否播放聊天关键词特效。
  static const String chatEffectsEnabled = 'CHAT_EFFECTS_ENABLED';

  /// 界面字号缩放（double）
  static const String textScaleFactor = 'TEXT_SCALE_FACTOR';

  /// 发送快捷键：'enter' / 'ctrlEnter'
  static const String chatSendShortcut = 'CHAT_SEND_SHORTCUT';

  /// 通知中是否显示消息预览（true=显示内容，false=仅提示有新消息）
  static const String messagePreviewEnabled = 'MESSAGE_PREVIEW_ENABLED';

  /// 是否自动播放视频/媒体
  static const String autoPlayMediaEnabled = 'AUTO_PLAY_MEDIA_ENABLED';

  /// 是否后台自动下载更新安装包（布尔值，true=有新版本时自动下载，默认开）
  static const String autoDownloadUpdate = 'AUTO_DOWNLOAD_UPDATE';

  /// 是否允许移动流量下载更新安装包（布尔值，默认关，仅 Wi-Fi/以太网自动下载）
  static const String updateCellularDownload = 'UPDATE_CELLULAR_DOWNLOAD';

  /// AI 会话 ID（按用户隔离，key 前缀 + userId）
  ///
  /// 用于持久化 `/chat/ai/stream` 返回的 `conversationId`，实现多轮记忆。
  /// 客户端在 done 事件中保存，下次请求时回传。
  static const String aiConversationIdPrefix = 'AI_CONVERSATION_ID_';

  /// 获取当前用户的 AI 会话持久化 key
  static String aiConversationIdKey(String userId) =>
      '$aiConversationIdPrefix$userId';

  /// Web 端 Google OAuth 回调前暂存的 PKCE verifier（整页跳转后读回即删）
  static const String oauthCodeVerifier = 'OAUTH_CODE_VERIFIER';

  /// Web 端 Google OAuth 回调前暂存的 state（防 CSRF，读回即删）
  static const String oauthState = 'OAUTH_STATE';
}
