/// 通知辅助类入口
///
/// 通过条件导出为不同平台提供实现：
/// - 原生平台（Android / iOS / 桌面）使用系统通知栏 / 角标 / 托盘实现 [_io]
/// - Web 端使用 no-op 桩 [_web]（浏览器无系统通知能力，消息实时性由 WebSocket 保证）
export 'notification_helper_io.dart' if (dart.library.html) 'notification_helper_web.dart';
