// 条件导出：Web 端(JS/WASM)使用 BroadcastChannel + storage 事件实现跨标签页
// 会话同步，原生平台使用桩。用 dart.library.io 判定（dart.library.html 在
// WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'cross_tab_session_sync_web.dart'
    if (dart.library.io) 'cross_tab_session_sync_stub.dart';
