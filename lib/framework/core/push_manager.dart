import 'dart:async';

import 'package:anoxia/framework/logs/talker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

class PushManager {
  PushManager._();

  static final PushManager instance = PushManager._();

  final JPushFlutterInterface _jpush = JPush.newJPush();
  static const Duration _fcmTokenTimeout = Duration(seconds: 4);
  static const Duration _jpushQueryTimeout = Duration(seconds: 3);

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

    // Android 默认维持后台长连接，这里显式设置，避免 ROM/版本差异导致行为不一致。
    _jpush.setBackgroundEnable(enable: true);

    _jpush.addEventHandler(
      onConnected: _onConnected,
      onReceiveNotification: _onReceiveNotification,
      onOpenNotification: _onOpenNotification,
      onReceiveMessage: _onReceiveMessage,
    );

    await _requestPermission();

    await Future.delayed(const Duration(milliseconds: 400));

    final rid = await getRegistrationId().timeout(
      _jpushQueryTimeout,
      onTimeout: () => '',
    );

    print('JPush RID => $rid');
    log.info('JPush RID => $rid');

    // FCM 在部分国内机型/网络环境下可能长时间阻塞，这里不阻塞主初始化链路。
    unawaited(_bindFcmTokenToJPush());
    unawaited(_logPushHealth());
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

  Future<void> _bindFcmTokenToJPush() async {
    try {
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(_fcmTokenTimeout, onTimeout: () => null);
      if (fcmToken == null || fcmToken.isEmpty) {
        log.warning('FCM token 获取超时或为空，跳过 setThirdToken');
        return;
      }

      _jpush.setThirdToken(token: fcmToken);
      log.info('FCM token 已绑定到极光 third token');

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (token.isNotEmpty) {
          _jpush.setThirdToken(token: token);
          log.info('FCM token 刷新，已重新绑定到极光 third token');
        }
      });
    } catch (e, stack) {
      log.error('绑定 FCM token 到极光失败', e, stack);
    }
  }

  Future<void> _logPushHealth() async {
    try {
      final notificationEnabled = await isNotificationEnabled().timeout(
        _jpushQueryTimeout,
        onTimeout: () => false,
      );
      final pushStatus = await _jpush.getPushStatus().timeout(
        _jpushQueryTimeout,
        onTimeout: () => <dynamic, dynamic>{'timeout': true},
      );
      final isPushStopped = await _jpush.isPushStoppedAndroid().timeout(
        _jpushQueryTimeout,
        onTimeout: () => false,
      );

      log.info(
        'Push health => notificationEnabled: $notificationEnabled, isPushStopped: $isPushStopped, status: $pushStatus',
      );
    } catch (e, stack) {
      log.error('读取推送健康状态失败', e, stack);
    }
  }
}