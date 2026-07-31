// 推送管理器公共类型定义，供原生实现(_io)与 Web 桩(_web)共享。
import 'dart:async';

typedef PushTokenChangedCallback = FutureOr<void> Function(String token);

typedef PushNotificationCallback =
    FutureOr<void> Function(Map<String, dynamic> payload);
