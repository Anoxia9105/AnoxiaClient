import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

class PushManager {
  PushManager._();

  static final PushManager instance = PushManager._();

  final JPushFlutterInterface _jpush = JPush.newJPush();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _initialized = true;

    _jpush.setup(
      appKey: 'c524d0a1de4ff5469e1c8298',
      channel: 'developer-default',
      production: false,
      debug: true,
    );

    _jpush.addEventHandler(
      onConnected: _onConnected,
      onReceiveNotification: _onReceiveNotification,
      onOpenNotification: _onOpenNotification,
      onReceiveMessage: _onReceiveMessage,
    );

    await _requestPermission();

    await Future.delayed(const Duration(seconds: 2));

    final rid = await getRegistrationId();

    print('JPush RID => $rid');
  }

  Future<void> _requestPermission() async {
    _jpush.requestRequiredPermission();
  }

  Future<dynamic> _onConnected(Map<String, dynamic> event) async {
    print('极光连接成功 => $event');
  }

  Future<dynamic> _onReceiveNotification(
    Map<String, dynamic> event,
  ) async {
    print('收到通知 => $event');
  }

  Future<dynamic> _onOpenNotification(
    Map<String, dynamic> event,
  ) async {
    print('点击通知 => $event');
  }

  Future<dynamic> _onReceiveMessage(
    Map<String, dynamic> event,
  ) async {
    print('收到透传消息 => $event');
  }

  Future<String> getRegistrationId() async {
    try {
      return await _jpush.getRegistrationID();
    } catch (_) {
      return '';
    }
  }

  Future<bool> isNotificationEnabled() {
    return _jpush.isNotificationEnabled();
  }
}