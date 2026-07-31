/// 推送管理器入口
///
/// 通过条件导出为不同平台提供实现：
/// - 原生平台（Android / iOS / 桌面）使用 JPush + FCM 双通道实现 [_io]
/// - Web 端使用 no-op 桩 [_web]（浏览器消息实时性由 WebSocket 长连接保证）
///
/// 公共类型（回调定义）统一来自 [push_manager_base]。
export 'push_manager_base.dart';
export 'push_manager_io.dart' if (dart.library.html) 'push_manager_web.dart';
