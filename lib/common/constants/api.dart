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

  /// 个人二维码内容前缀（`/u/{userId}`）。
  ///
  /// 二维码编码的是链接而非 JSON，微信等外部扫码器可识别为 URL；
  /// 后端同名路由提供用户名片落地页（AnoxiaServer UserQrController）。
  static const String qrUserBaseUrl = 'https://chat.anoxia.cn/u/';

  /// 群聊二维码内容前缀（`/g/{roomId}`）。
  ///
  /// 与个人二维码相同，编码的是链接而非 JSON，外部扫码器打开后端同名
  /// 路由（AnoxiaServer GroupQrController）看到的是群信息落地页；
  /// App 内扫码则由扫码页解析 URL 直接拉起群预览/加入流程。
  static const String qrGroupBaseUrl = 'https://chat.anoxia.cn/g/';

  /// 应用更新检查接口
  static const String appUpdateLatest = '/app/update/latest';

  // ======================== 认证接口 ========================
  /// 用户登录接口
  static const String login = '/login';

  /// 用户注册
  static const String register = '/register';

  /// 注册邮箱验证码
  static const String registerSendEmailCode = '/register/send-email-code';

  /// 校验注册邮箱验证码并获取短期注册凭证
  static const String registerVerifyEmailCode = '/register/verify-email-code';

  /// 用户登出接口
  static const String logout = '/logout';

  /// 获取当前用户信息接口
  static const String getInfo = '/getInfo';

  /// 获取图形验证码接口
  static const String captchaImage = '/captchaImage';

  /// 创建扫码登录会话（桌面/Web 展示二维码）
  static const String scanLoginCreate = '/login/scan/create';

  /// 查询扫码登录会话状态（桌面/Web 轮询）
  static const String scanLoginStatus = '/login/scan/status';

  /// 手机端确认扫码登录
  static const String scanLoginConfirm = '/login/scan/confirm';

  /// 忘记密码发送验证码
  static const String forgotPasswordSendCode = '/password/forgot/send-code';

  /// 忘记密码校验邮箱验证码并获取重置凭证
  static const String forgotPasswordVerifyCode = '/password/forgot/verify-code';

  /// 忘记密码重置密码
  static const String forgotPasswordReset = '/password/forgot/reset';

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

  /// 上传/更新当前用户头像
  static const String userAvatarUpload = '/system/user/profile/avatar';

  /// 更新用户密码
  static const String userProfileUpdatePassword =
      '/system/user/profile/updatePwd';

  /// 提交用户反馈
  static const String feedbackSubmit = '/feedback/submit';
  static const String feedbackSubmitWithImages = '/feedback/submit/images';

  // ======================== 聊天室接口 ========================
  /// 获取聊天室列表
  static const String chatRooms = '/chat/rooms';

  /// 创建私聊聊天室
  static const String chatCreatePrivate = '/chat/createPrivate';

  /// 创建群聊
  static const String chatCreateGroup = '/chat/createGroup';
  static const String chatGroupPreview = '/chat/group/preview';
  static const String chatGroupJoin = '/chat/group/join';
  static const String chatGroupJoinRequests = '/chat/group/joinRequests';
  static const String chatGroupJoinRequestHandle =
      '/chat/group/joinRequest/handle';

  /// 离开聊天室
  static const String chatRoomLeave = '/chat/room/leave';

  /// 解散群聊
  static const String chatRoomDisband = '/chat/room/disband';

  /// 添加群成员
  static const String chatRoomAddMembers = '/chat/room/addMembers';

  /// 修改群聊名称
  static const String chatRoomUpdateName = '/chat/room/updateName';

  /// 修改群公告
  static const String chatRoomUpdateAnnouncement =
      '/chat/room/updateAnnouncement';

  /// 踢出群成员
  static const String chatRoomKickMember = '/chat/room/kickMember';

  /// 禁言/解除禁言群聊
  static const String chatRoomMute = '/chat/room/muteRoom';

  // ======================== 消息接口 ========================
  /// 获取聊天历史记录
  static const String chatHistory = '/chat/history';

  /// REST fallback for sending a message when WebSocket integration is not used.
  static const String chatSendMessage = '/chat/message/send';

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

  /// 取消收藏消息
  static const String chatFavoriteRemove = '/chat/favorite/remove';

  /// 获取收藏列表
  static const String chatFavoriteList = '/chat/favorite/list';

  /// 获取表情包列表（含包内表情）
  static const String stickerPacks = '/chat/sticker/packs';

  /// 创建用户自定义表情包
  static const String stickerCustomPack = '/chat/sticker/custom/pack';

  /// 向用户自定义表情包新增表情
  static const String stickerCustomSticker = '/chat/sticker/custom/sticker';

  /// 删除用户自定义表情包（{id}）
  static const String stickerCustomPackDelete = '/chat/sticker/custom/pack';

  /// 删除用户自定义表情包内的单个表情（{id}）
  static const String stickerCustomStickerDelete =
      '/chat/sticker/custom/sticker';

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

  // ======================== 推送设备绑定接口 ========================
  /// 登录后绑定/刷新设备推送标识
  static const String pushDeviceBind = '/push/device/bind';

  /// 登出解绑设备
  static const String pushDeviceUnbind = '/push/device/unbind';
}
