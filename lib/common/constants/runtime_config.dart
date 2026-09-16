import '../../platform/shims/runtime_config_shim.dart';

/// 客户端接口地址解析。
///
/// 优先使用部署期注入的运行时配置（Flutter Web 由 anoxia-install.sh 生成的
/// `runtime-config.js` 提供），未配置时回退到内置默认值（线上 chat/live 域名）。
/// 这样同一份 Web 打包产物无需按环境重新编译。
class RuntimeConfig {
  const RuntimeConfig._();

  /// 内置默认值：线上环境
  static const String defaultHttpBaseUrl = 'https://chat.anoxia.cn/api';
  static const String defaultWsBaseUrl =
      'wss://chat.anoxia.cn/chat?token=';
  static const String defaultWsRoomBaseUrl = 'wss://live.anoxia.cn';
  static const String defaultQrUserBaseUrl = 'https://chat.anoxia.cn/u/';
  static const String defaultQrGroupBaseUrl = 'https://chat.anoxia.cn/g/';

  static String get httpBaseUrl =>
      RuntimeConfigOverrides.httpBaseUrl ?? defaultHttpBaseUrl;

  static String get wsBaseUrl =>
      RuntimeConfigOverrides.wsBaseUrl ?? defaultWsBaseUrl;

  static String get wsRoomBaseUrl =>
      RuntimeConfigOverrides.wsRoomBaseUrl ?? defaultWsRoomBaseUrl;

  static String get qrUserBaseUrl =>
      RuntimeConfigOverrides.qrUserBaseUrl ?? defaultQrUserBaseUrl;

  static String get qrGroupBaseUrl =>
      RuntimeConfigOverrides.qrGroupBaseUrl ?? defaultQrGroupBaseUrl;
}
