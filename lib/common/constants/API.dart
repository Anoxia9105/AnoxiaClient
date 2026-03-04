class API {
  // static const String httpBaseUrl = 'http://127.0.0.1:8080';
  // static const String wsBaseUrl = 'ws://127.0.0.1:8081?token=';
  // static const String wsRoomBaseUrl = 'ws://8.137.14.21:7880';

  // static const String httpBaseUrl = 'http://8.137.14.21:8080';
  // static const String wsBaseUrl = 'ws://8.137.14.21:8081?token=';
  // static const String wsRoomBaseUrl = 'ws://8.137.14.21:7880';

  static const String httpBaseUrl = 'https://chat.anoxia.cn/api';
  static const String wsBaseUrl = 'wss://chat.anoxia.cn/chat?token=';
  static const String wsRoomBaseUrl = 'wss://live.anoxia.cn';

  //更新地址
  static const String updateUrl = 'http://8.137.14.21/version.json';

  // ======================== 认证接口 ========================
  static const String login = '/login';
  static const String logout = '/logout';
  static const String getInfo = '/getInfo';
  static const String captchaImage = '/captchaImage';

  // ======================== 好友/联系人接口 ========================
  static const String contactList = '/contact/list';
  static const String contactRequest = '/contact/request';
  static const String contactAcceptRequest = '/contact/acceptRequest';
  static const String contactSearch = '/contact/search';
  static const String contactRequestCreate = '/contact/request';
  static const String contactUserDetail = '/contact/userDetail';

  // ======================== 聊天室接口 ========================
  static const String chatRooms = '/chat/rooms';
  static const String chatCreatePrivate = '/chat/createPrivate';
  static const String chatCreateGroup = '/chat/createGroup';
  static const String chatRoomLeave = '/chat/room/leave';
  static const String chatRoomDisband = '/chat/room/disband';
  static const String chatRoomAddMembers = '/chat/room/addMembers';

  // ======================== 消息接口 ========================
  static const String chatHistory = '/chat/history';
  static const String chatMembers = '/chat/members';
  static const String chatReadReport = '/chat/readReport';
  static const String chatSearch = '/chat/search';

  // ======================== AI 聊天接口 ========================
  static const String chatGemini = '/chat/gemini';
}
