// 原生端（Android/iOS/桌面）：没有 Web 那样的部署期注入机制，
// 也没有可读取的当前站点地址，因此使用内置的正式服务器地址。
// Web 端的默认值见 runtime_config_web.dart（按当前页面地址运行时推断）。
class RuntimeConfigOverrides {
  static String? get httpBaseUrl => null;
  static String? get wsBaseUrl => null;
  static String? get wsRoomBaseUrl => null;
  static String? get qrUserBaseUrl => null;
  static String? get qrGroupBaseUrl => null;

  /// 原生端无运行时注入，Google Client ID 只走编译期 dart-define。
  static String? get googleClientId => null;
}

class RuntimeConfigDefaults {
  static const String httpBaseUrl = 'https://chat.anoxia.cn/api';
  static const String wsBaseUrl = 'wss://chat.anoxia.cn/chat?token=';
  static const String wsRoomBaseUrl = 'wss://live.anoxia.cn';
  static const String qrUserBaseUrl = 'https://chat.anoxia.cn/u/';
  static const String qrGroupBaseUrl = 'https://chat.anoxia.cn/g/';
}
