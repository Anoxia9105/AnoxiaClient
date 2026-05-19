/// API 接口常量定义
///
/// 集中管理应用所有后端接口地址，包括 HTTP 和 WebSocket 接口
class API {
  // static const String httpBaseUrl = 'http://127.0.0.1:8080';
  // static const String wsBaseUrl = 'ws://127.0.0.1:8081?token=';
  // static const String wsRoomBaseUrl = 'ws://8.137.14.21:7880';

  // static const String httpBaseUrl = 'http://8.137.14.21:8080';
  // static const String wsBaseUrl = 'ws://8.137.14.21:8081?token=';
  // static const String wsRoomBaseUrl = 'ws://8.137.14.21:7880';

  /// HTTP 接口基础地址
  static const String httpBaseUrl = 'https://chat.anoxia.cn/api';
  /// WebSocket 聊天接口地址
  static const String wsBaseUrl = 'wss://chat.anoxia.cn/chat?token=';
  /// WebSocket 实时音视频通话接口地址
  static const String wsRoomBaseUrl = 'wss://live.anoxia.cn';

  /// 应用更新检查接口
  static const String appUpdateLatest = '/app/update/latest';

  // ======================== 认证接口 ========================
  /// 用户登录接口
  static const String login = '/login';
  /// 用户登出接口
  static const String logout = '/logout';
  /// 获取当前用户信息接口
  static const String getInfo = '/getInfo';
  /// 获取图形验证码接口
  static const String captchaImage = '/captchaImage';

  // ======================== 好友/联系人接口 ========================
  /// 获取联系人列表
  static const String contactList = '/contact/list';
  /// 获取好友请求列表
  static const String contactRequest = '/contact/request';
  /// 接受好友请求
  static const String contactAcceptRequest = '/contact/acceptRequest';
  /// 搜索用户
  static const String contactSearch = '/contact/search';
  /// 发送好友请求
  static const String contactRequestCreate = '/contact/request';
  /// 获取联系人详细信息
  static const String contactUserDetail = '/contact/userDetail';
  /// 更新联系人备注
  static const String contactRemarkUpdate = '/contact/remark';
  /// 删除联系人
  static const String contactDelete = '/contact/delete';

  // ======================== 个人中心接口 ========================
  /// 更新用户个人资料
  static const String userProfileUpdate = '/system/user/profile';
  /// 更新用户密码
  static const String userProfileUpdatePassword =
      '/system/user/profile/updatePwd';
  /// 提交用户反馈
  static const String feedbackSubmit = '/feedback/submit';

  // ======================== 聊天室接口 ========================
  /// 获取聊天室列表
  static const String chatRooms = '/chat/rooms';
  /// 创建私聊聊天室
  static const String chatCreatePrivate = '/chat/createPrivate';
  /// 创建群聊
  static const String chatCreateGroup = '/chat/createGroup';
  /// 离开聊天室
  static const String chatRoomLeave = '/chat/room/leave';
  /// 解散群聊
  static const String chatRoomDisband = '/chat/room/disband';
  /// 添加群成员
  static const String chatRoomAddMembers = '/chat/room/addMembers';
  /// 踢出群成员
  static const String chatRoomKickMember = '/chat/room/kickMember';
  /// 禁言/解除禁言群聊
  static const String chatRoomMute = '/chat/room/muteRoom';

  // ======================== 消息接口 ========================
  /// 获取聊天历史记录
  static const String chatHistory = '/chat/history';
  /// 获取聊天室成员
  static const String chatMembers = '/chat/members';
  /// 上报消息已读状态
  static const String chatReadReport = '/chat/readReport';
  /// 搜索聊天消息
  static const String chatSearch = '/chat/search';
  /// 撤回消息
  static const String chatRecall = '/chat/recall';
  /// 收藏消息
  static const String chatFavoriteAdd = '/chat/favorite/add';
  /// 获取收藏列表
  static const String chatFavoriteList = '/chat/favorite/list';

  // ======================== 通话 ========================
  /// 获取通话 token
  static const String callToken = '/call/token';
  /// 获取通话状态
  static const String callStatus = '/call/status';
  /// 移出通话参与者
  static const String callRemoveParticipant = '/call/participant/remove';

  // ======================== AI 聊天接口 ========================
  /// AI 对话接口
  static const String chatGemini = '/chat/gemini';
}
