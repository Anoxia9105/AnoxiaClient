import 'dart:convert';
import 'dart:async';

import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:uuid/uuid.dart';

typedef PushTokenChangedCallback = FutureOr<void> Function(String token);
typedef PushNotificationCallback =
    FutureOr<void> Function(Map<String, dynamic> payload);

class PushManager {
  PushManager._();

  static final PushManager instance = PushManager._();

  final JPushFlutterInterface _jpush = JPush.newJPush();
  static const Duration _fcmTokenTimeout = Duration(seconds: 10);
  static const Duration _jpushQueryTimeout = Duration(seconds: 5);
  static const String _appId = 'cn.anoxia';
  static const int _env = 0;
  static const String _deviceUidKey = 'push_device_uid';

  bool _initialized = false;
  String? _latestFcmToken;
  PushTokenChangedCallback? _onFcmTokenChanged;
  StreamSubscription<String>? _fcmTokenRefreshSub;
  PushNotificationCallback? _onNotification;
  Map<String, dynamic>? _pendingNotification;

  Future<void> init() async {
    if (_initialized) return;

    _initialized = true;

    try {
      _jpush.setup(
        appKey: 'c524d0a1de4ff5469e1c8298',
        channel: 'developer-default',
        production: false,
        debug: true,
      );

      // 前台时不展示系统通知栏，避免用户正在聊天页时被重复打扰。
      _jpush.setUnShowAtTheForeground(unShow: true);

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

      log.info('JPush RID => $rid');

      // FCM 在部分国内机型/网络环境下可能长时间阻塞，这里不阻塞主初始化链路。
      unawaited(_bindFcmTokenToJPush());
      unawaited(_logPushHealth());
    } catch (e, stack) {
      _initialized = false;
      log.error('PushManager init 失败', e, stack);
    }
  }

  Future<void> _requestPermission() async {
    _jpush.requestRequiredPermission();
  }

  Future<dynamic> _onConnected(Map<String, dynamic> event) async {
    log.info('极光连接成功 => $event');
  }

  Future<dynamic> _onReceiveNotification(Map<String, dynamic> event) async {
    log.info('收到通知 => $event');
    _dispatchNotification(event);
  }

  Future<dynamic> _onOpenNotification(Map<String, dynamic> event) async {
    log.info('点击通知 => $event');
    _dispatchNotification(event);
  }

  Future<dynamic> _onReceiveMessage(Map<String, dynamic> event) async {
    log.info('收到透传消息 => $event');
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
      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        _fcmTokenTimeout,
        onTimeout: () => null,
      );
      if (fcmToken == null || fcmToken.isEmpty) {
        log.warning('FCM token 获取超时或为空，跳过 setThirdToken');
        return;
      }

      _latestFcmToken = fcmToken;
      _jpush.setThirdToken(token: fcmToken);
      log.info('FCM token 已绑定到极光 third token');
      _notifyFcmTokenChanged(fcmToken);

      _fcmTokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) {
        if (token.isNotEmpty) {
          _latestFcmToken = token;
          _jpush.setThirdToken(token: token);
          log.info('FCM token 刷新，已重新绑定到极光 third token');
          _notifyFcmTokenChanged(token);
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

  Future<String> getOrCreateDeviceUid() async {
    final cached = SPUtil.instance.get(_deviceUidKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final uid = const Uuid().v4();
    await SPUtil.instance.set(_deviceUidKey, uid);
    return uid;
  }

  Future<Map<String, dynamic>> buildDeviceBindPayload({
    required int userId,
  }) async {
    final rid = await getRegistrationId().timeout(
      _jpushQueryTimeout,
      onTimeout: () => '',
    );

    final token =
        _latestFcmToken ??
        await FirebaseMessaging.instance.getToken().timeout(
          _fcmTokenTimeout,
          onTimeout: () => null,
        );

    if (token != null && token.isNotEmpty) {
      _latestFcmToken = token;
    }

    return {
      'appId': _appId,
      'env': _env,
      'platform': _platformCode,
      'userId': userId,
      'deviceUid': await getOrCreateDeviceUid(),
      'jpushRid': rid.isEmpty ? null : rid,
      'fcmToken': _latestFcmToken,
      'vendorToken': null,
      'pushEnabled': 1,
      'status': 1,
    };
  }

  void setOnFcmTokenChanged(PushTokenChangedCallback? callback) {
    _onFcmTokenChanged = callback;
  }

  void setOnNotification(PushNotificationCallback? callback) {
    _onNotification = callback;
    final pending = _pendingNotification;
    if (callback != null && pending != null) {
      _pendingNotification = null;
      unawaited(Future.sync(() => callback(pending)));
    }
  }

  void _dispatchNotification(Map<String, dynamic> event) {
    final payload = _flattenNotificationPayload(event);
    final callback = _onNotification;
    if (callback == null) {
      _pendingNotification = payload;
      return;
    }
    unawaited(
      Future.sync(() => callback(payload)).catchError((error, stackTrace) {
        log.error('处理推送通知失败', error, stackTrace);
      }),
    );
  }

  Map<String, dynamic> _flattenNotificationPayload(Map<String, dynamic> event) {
    final result = <String, dynamic>{...event};
    void merge(dynamic value) {
      if (value is Map) {
        for (final entry in value.entries) {
          result[entry.key.toString()] = entry.value;
        }
      } else if (value is String && value.trimLeft().startsWith('{')) {
        try {
          merge(jsonDecode(value));
        } catch (_) {
          // Keep the original field when a vendor-specific value is not JSON.
        }
      }
    }

    for (final key in const <String>['extras', 'extra', 'data']) {
      merge(event[key]);
    }
    return result;
  }

  void _notifyFcmTokenChanged(String token) {
    final callback = _onFcmTokenChanged;
    if (callback == null) return;

    unawaited(
      Future.sync(() => callback(token)).catchError((error, stackTrace) {
        log.error('FCM token 变更回调执行失败', error, stackTrace);
      }),
    );
  }

  int get _platformCode {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 1;
      case TargetPlatform.iOS:
        return 2;
      default:
        return 0;
    }
  }
}
