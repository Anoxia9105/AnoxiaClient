// Web 端运行时配置：优先读取 web/runtime-config.js 注入的 window.__ANOXIA_CONFIG__，
// 未注入时按当前页面地址（window.location / Uri.base）运行时推断同源接口地址，
// 因此打包产物不含任何域名/IP 常量，部署到任意主机均可直接使用。
//
// 部署脚本（anoxia-install.sh）会生成 runtime-config.js 写入本机实际地址
// （含域名模式的 chat/live/oss 子域）；缺失时这里的同源推断保证仍可用。
//
// 使用 dart:js_interop（JS/WASM 双兼容），不使用 dart:html。
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('__ANOXIA_CONFIG__')
external JSObject? get _anoxiaConfig;

/// 运行时配置覆盖项（全部可空，缺省表示按当前站点地址自动推断）。
class RuntimeConfigOverrides {
  static String? get httpBaseUrl => _read('httpBaseUrl');
  static String? get wsBaseUrl => _read('wsBaseUrl');
  static String? get wsRoomBaseUrl => _read('wsRoomBaseUrl');
  static String? get qrUserBaseUrl => _read('qrUserBaseUrl');
  static String? get qrGroupBaseUrl => _read('qrGroupBaseUrl');

  /// Google OAuth Web 客户端 ID（部署期经 runtime-config.js 注入，Docker 入口
  /// 由 GOOGLE_OAUTH_CLIENT_ID 环境变量渲染；未注入时回退编译期 dart-define）。
  static String? get googleClientId => _read('googleClientId');

  static String? _read(String key) {
    try {
      final config = _anoxiaConfig;
      if (config == null) return null;
      final value = config.getProperty<JSAny?>(key.toJS);
      if (value == null || !value.isA<JSString>()) return null;
      final text = (value as JSString).toDart.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }
}

/// 未注入运行时配置时的兜底：按当前页面地址（域名或 IP）推断本机接口，
/// 不写死任何生产域名。
class RuntimeConfigDefaults {
  static Uri get _base => Uri.base;

  static String get _httpOrigin {
    final base = _base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return base.origin;
    }
    final port = base.hasPort ? ':${base.port}' : '';
    return '${base.scheme}://${base.host}$port';
  }

  /// 音视频信令主机：chat./www. 子域按约定派生到 live. 子域，
  /// 其它（如 IP 直连）保持同源，通过 /livekit 反代访问。
  static String _liveHost(String host) {
    if (host.startsWith('chat.')) return 'live.${host.substring(5)}';
    if (host.startsWith('www.')) return 'live.${host.substring(4)}';
    return host;
  }

  static String get httpBaseUrl => '$_httpOrigin/api';
  static String get wsBaseUrl => '${_wsScheme(_base.host)}/chat?token=';
  static String get wsRoomBaseUrl {
    final base = _base;
    final liveHost = _liveHost(base.host);
    final origin = _wsScheme(liveHost);
    // 派生到独立 live 子域时直接连该域；否则走同源 /livekit 反代
    return liveHost == base.host ? '$origin/livekit' : origin;
  }

  static String _wsScheme(String host) {
    final base = _base;
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final port = base.hasPort ? ':${base.port}' : '';
    return '$scheme://$host$port';
  }

  static String get qrUserBaseUrl => '$_httpOrigin/u/';
  static String get qrGroupBaseUrl => '$_httpOrigin/g/';
}
