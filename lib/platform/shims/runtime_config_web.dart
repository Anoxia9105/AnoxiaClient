// Web 端运行时配置：读取 web/runtime-config.js 注入的 window.__ANOXIA_CONFIG__。
//
// 部署脚本（anoxia-install.sh）会在 Web 根目录生成 runtime-config.js，写入本机
// 实际的接口地址，使同一份 Flutter Web 打包产物可直接部署到任意机器，无需为
// 每个环境重新编译。未注入对应字段时返回 null，由 RuntimeConfig 回退默认值。
//
// 使用 package:web 同族的 dart:js_interop（JS/WASM 双兼容），不使用 dart:html。
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('__ANOXIA_CONFIG__')
external JSObject? get _anoxiaConfig;

/// 运行时配置覆盖项（全部可空，缺省表示使用编译期默认值）。
class RuntimeConfigOverrides {
  static String? get httpBaseUrl => _read('httpBaseUrl');
  static String? get wsBaseUrl => _read('wsBaseUrl');
  static String? get wsRoomBaseUrl => _read('wsRoomBaseUrl');
  static String? get qrUserBaseUrl => _read('qrUserBaseUrl');
  static String? get qrGroupBaseUrl => _read('qrGroupBaseUrl');

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
