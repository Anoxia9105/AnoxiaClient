import '../../platform/shims/runtime_config_shim.dart';

/// 客户端接口地址解析。
///
/// 优先使用运行时配置：
/// - Flutter Web：读取部署期注入的 `runtime-config.js`（window.__ANOXIA_CONFIG__），
///   未注入时按当前页面地址（域名或 IP）运行时推断同源接口，产物不写死域名。
/// - 原生端：无运行时注入机制，使用平台内置的正式服务器地址（见 io shim）。
class RuntimeConfig {
  const RuntimeConfig._();

  static String get httpBaseUrl =>
      RuntimeConfigOverrides.httpBaseUrl ?? RuntimeConfigDefaults.httpBaseUrl;

  static String get wsBaseUrl =>
      RuntimeConfigOverrides.wsBaseUrl ?? RuntimeConfigDefaults.wsBaseUrl;

  static String get wsRoomBaseUrl =>
      RuntimeConfigOverrides.wsRoomBaseUrl ?? RuntimeConfigDefaults.wsRoomBaseUrl;

  static String get qrUserBaseUrl =>
      RuntimeConfigOverrides.qrUserBaseUrl ?? RuntimeConfigDefaults.qrUserBaseUrl;

  static String get qrGroupBaseUrl =>
      RuntimeConfigOverrides.qrGroupBaseUrl ?? RuntimeConfigDefaults.qrGroupBaseUrl;
}
