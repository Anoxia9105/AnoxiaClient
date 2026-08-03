// Web 端推送管理器桩。Web 没有 JPush/FCM，所有方法为 no-op。
// 浏览器端消息实时性由 WebSocket 长连接保证，无需独立推送通道。
import 'dart:async';

import 'package:anoxia/framework/core/push_manager_base.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

class PushManager {
  PushManager._();
  static final PushManager instance = PushManager._();

  bool _initialized = false;
  void Function(String roomId)? _onOpenRoom;
  FutureOr<void> Function(String actionId, Map<String, dynamic> payload)?
  _onCallAction;

  Future<void> init() async {
    _initialized = true;
  }

  Future<void> _requestPermission() async {}
  Future<dynamic> _onConnected(Map<String, dynamic> event) async {}
  Future<dynamic> _onReceiveNotification(Map<String, dynamic> event) async {}
  Future<dynamic> _onOpenNotification(Map<String, dynamic> event) async {}
  Future<dynamic> _onReceiveMessage(Map<String, dynamic> event) async {}

  Future<String> getRegistrationId() async => '';
  Future<bool> isNotificationEnabled() async => false;
  Future<void> _bindFcmTokenToJPush() async {}
  Future<void> _logPushHealth() async {}

  Future<String> getOrCreateDeviceUid() async {
    // 浏览器无稳定设备标识，须持久化到 localStorage，否则每次调用都生成新
    // UUID，会导致后端把同一 Web 端识别为多个重复设备。
    const key = 'anoxia_web_device_uid';
    final existing = web.window.localStorage.getItem(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final uid = const Uuid().v4();
    web.window.localStorage.setItem(key, uid);
    return uid;
  }

  Future<Map<String, dynamic>> buildDeviceBindPayload({
    required int userId,
  }) async =>
      <String, dynamic>{
        'appId': 'cn.anoxia',
        'env': 0,
        'platform': 0,
        'userId': userId,
        'deviceUid': await getOrCreateDeviceUid(),
        'jpushRid': null,
        'fcmToken': null,
        'vendorToken': null,
        'pushEnabled': 0,
        'status': 1,
      };

  void setOnFcmTokenChanged(PushTokenChangedCallback? callback) {}
  void setOnNotification(PushNotificationCallback? callback) {}
  void _dispatchNotification(Map<String, dynamic> event) {}
  Map<String, dynamic> _flattenNotificationPayload(Map<String, dynamic> event) =>
      event;
  void _notifyFcmTokenChanged(String token) {}
  int get _platformCode => 0;
}
