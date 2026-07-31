// Web 端通知辅助类实现。
//
// 浏览器使用原生 Notification API 展示系统通知；实时性由 WebSocket 长连接保证，
// 收到消息时由业务层调用 show/showIncomingCall 弹通知。点击通知跳转对应房间。
//
// 公共 API 与 [_io] 实现保持一致，以便调用点无需区分平台。
import 'dart:async';
import 'dart:html' as html;

class NotificationHelper {
  NotificationHelper._internal();
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;

  static const String callAcceptAction = 'call_accept';
  static const String callRejectAction = 'call_reject';

  void Function(String roomId)? _onOpenRoom;
  FutureOr<void> Function(String actionId, Map<String, dynamic> payload)?
  _onCallAction;
  html.Notification? _incomingCallNotification;
  String _baseTitle = 'Anoxia';

  void configure({
    required void Function(String roomId) onOpenRoom,
    FutureOr<void> Function(String actionId, Map<String, dynamic> payload)?
    onCallAction,
  }) {
    _onOpenRoom = onOpenRoom;
    _onCallAction = onCallAction;
  }

  Future<void> init() async {
    // Web 端不再注册全局手势监听来自动弹通知授权。浏览器只允许在明确的用户
    // 手势（如设置页的“开启通知”按钮）中申请权限，静默/全局监听会干扰用户
    // 操作且易被拒绝。授权统一由 requestPermission() 在用户主动操作时触发。
    return;
  }

  /// 主动申请通知权限，应在用户手势（按钮点击、设置开关等）中调用。
  ///
  /// 返回是否已被授予。浏览器不支持或被拒绝时返回 false。
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    if (html.Notification.permission == 'denied') return false;
    final result = await html.Notification.requestPermission();
    return result == 'granted';
  }

  /// 当前通知权限是否已授予（同步查询浏览器状态，不会弹窗）。
  Future<bool> isPermissionGranted() async {
    if (!html.Notification.supported) return false;
    return html.Notification.permission == 'granted';
  }

  /// 浏览器是否支持通知 API。
  bool get isSupported => html.Notification.supported;

  /// 权限是否已被用户永久拒绝（此时只能引导用户去浏览器设置里改）。
  bool get isPermissionDenied =>
      html.Notification.supported && html.Notification.permission == 'denied';

  /// 确保通知权限已授予。
  ///
  /// 仅在权限已是 granted 时才允许弹通知；不再在异步消息路径中申请权限
  /// （浏览器会拒绝非手势上下文的申请），授权应由 [requestPermission] 完成。
  Future<bool> _ensurePermission() async {
    if (!html.Notification.supported) return false;
    return html.Notification.permission == 'granted';
  }

  /// 发送普通消息通知。
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? avatarUrl,
    bool force = false,
  }) async {
    if (!await _ensurePermission()) return;

    final notification = html.Notification(title, body: body, icon: avatarUrl);
    notification.onClick.listen((_) {
      if (payload != null && payload.isNotEmpty) {
        _onOpenRoom?.call(payload);
      }
      notification.close();
    });
  }

  /// 显示来电通知。
  ///
  /// 浏览器原生通知不支持内嵌接听/拒绝按钮（需 ServiceWorker 持久通知），
  /// 这里展示可点击的通知，点击后跳转到对应房间，接听/拒绝在应用内 UI 完成。
  Future<void> showIncomingCall({
    required Map<String, dynamic> payload,
    required String title,
    required String body,
    String? avatarUrl,
  }) async {
    if (!await _ensurePermission()) return;

    _incomingCallNotification = html.Notification(title, body: body, icon: avatarUrl);
    _incomingCallNotification?.onClick.listen((_) {
      final roomId = payload['roomId']?.toString() ?? '';
      if (roomId.isNotEmpty) _onOpenRoom?.call(roomId);
      _incomingCallNotification?.close();
      _incomingCallNotification = null;
    });
  }

  Future<void> cancelIncomingCall(String inviteId) async {
    _incomingCallNotification?.close();
    _incomingCallNotification = null;
  }

  int incomingCallNotificationId(String inviteId) =>
      0x3fffffff & inviteId.hashCode;

  /// 更新未读角标。
  ///
  /// 浏览器无法写入操作系统角标，这里把未读数反映到文档标题（如 "(3) Anoxia"）。
  Future<void> updateUnreadBadge(int count) async {
    if (count > 0) {
      html.document.title = '($count) $_baseTitle';
    } else {
      html.document.title = _baseTitle;
    }
  }
}
