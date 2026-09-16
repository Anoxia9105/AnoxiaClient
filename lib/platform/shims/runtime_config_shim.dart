// 条件导出：Web 端(JS/WASM)读取部署脚本注入的 window.__ANOXIA_CONFIG__，
// 原生端没有该机制，返回 null 由上层回退内置默认值。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，
// 详见 desktop_multi_window_shim 注释）。
export 'runtime_config_web.dart'
    if (dart.library.io) 'runtime_config_io.dart';
