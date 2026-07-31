/// 推送管理器（原生平台实现：JPush + FCM）
///
/// 统一管理 JPush 和 FCM 双通道推送：初始化、权限请求、Token 绑定、通知分发、
/// 设备绑定载荷构建等。通过单例模式提供全局访问入口。
/// Web 端使用 push_manager_web.dart（no-op 桩），由 push_manager.dart 条件导出。
import 'dart:convert';
import 'dart:async';

import 'package:anoxia/framework/core/device_identity.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

import 'push_manager_base.dart';

/// Push Token 变更回调（与 push_manager_base.dart 中定义一致）
/// Push 通知回调（与 push_manager_base.dart 中定义一致）

/// 推送管理器
///
/// 统一管理 JPush 和 FCM 双通道推送，负责初始化、权限请求、Token 绑定、
/// 通知分发、设备绑定载荷构建等。单例模式，通过 [PushManager.instance] 访问。
class PushManager {
  PushManager._();

  /// 单例实例
  static final PushManager instance = PushManager._();

  final JPushFlutterInterface _jpush = JPush.newJPush();
  static const Duration _fcmTokenTimeout = Duration(seconds: 10);
  static const Duration _jpushQueryTimeout = Duration(seconds: 5);
  static const String _appId = 'cn.anoxia';
  static const int _env = 0;

  bool _initialized = false;
  String? _latestFcmToken;
  PushTokenChangedCallback? _onFcmTokenChanged;
  StreamSubscription<String>? _fcmTokenRefreshSub;
  PushNotificationCallback? _onNotification;
  Map<String, dynamic>? _pendingNotification;

  /// 初始化推送服务
  ///
  /// 配置 JPush 并请求通知权限，同时异步绑定 FCM Token 到极光。
  /// 若已初始化则直接返回，避免重复初始化。
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

  /// 获取 JPush 注册 ID
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

      _fcmTokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) {
          if (token.isNotEmpty) {
            _latestFcmToken = token;
            _jpush.setThirdToken(token: token);
            log.info('FCM token 刷新，已重新绑定到极光 third token');
            _notifyFcmTokenChanged(token);
          }
        },
      );
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

  /// 获取或创建设备唯一标识
  Future<String> getOrCreateDeviceUid() async {
    return DeviceIdentity.instance.getOrCreate();
  }

  Future<Map<String, dynamic>> buildDeviceBindPayload({
    required int userId,
  }) async {
    // 1. 安全获取 JPush Registration ID
    String rid = '';
    try {
      rid = await getRegistrationId().timeout(
        _jpushQueryTimeout,
        onTimeout: () => '',
      );
    } catch (e) {
      // 容错处理：记录日志或忽略
      print('获取 JPush RID 异常: $e');
    }

    // 2. 安全获取 FCM Token（防止 FirebaseInstallationsException 导致 Crash）
    if (_latestFcmToken == null || _latestFcmToken!.isEmpty) {
      try {
        final token = await FirebaseMessaging.instance.getToken().timeout(
          _fcmTokenTimeout,
          onTimeout: () => null,
        );

        if (token != null && token.isNotEmpty) {
          _latestFcmToken = token;
        }
      } catch (e) {
        // 当国内网络打不通 Google 服务或缺少 GMS 时，优雅降级，防止应用崩溃
        print('获取 FCM Token 失败 (可能无 GMS 或网络不可达): $e');
        _latestFcmToken = null;
      }
    }

    // 3. 构建并返回 Payload
    return {
      'appId': _appId,
      'env': _env,
      'platform': _platformCode,
      'userId': userId,
      'deviceUid': await getOrCreateDeviceUid(),
      'jpushRid': rid.isEmpty ? null : rid,
      'fcmToken': (_latestFcmToken != null && _latestFcmToken!.isNotEmpty)
          ? _latestFcmToken
          : null,
      'vendorToken': null,
      'pushEnabled': 1,
      'status': 1,
    };
  }

  /// 设置 FCM Token 变更回调
  void setOnFcmTokenChanged(PushTokenChangedCallback? callback) {
    _onFcmTokenChanged = callback;
  }

  /// 设置推送通知回调
  ///
  /// 若设置回调时存在待处理的通知，则立即消费该通知。
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
