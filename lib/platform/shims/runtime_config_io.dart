// 原生端运行时配置：各平台使用编译期内置默认值（生产域名），
// 没有 Web 那样的部署期注入机制，因此全部返回 null。
class RuntimeConfigOverrides {
  static String? get httpBaseUrl => null;
  static String? get wsBaseUrl => null;
  static String? get wsRoomBaseUrl => null;
  static String? get qrUserBaseUrl => null;
  static String? get qrGroupBaseUrl => null;
}
