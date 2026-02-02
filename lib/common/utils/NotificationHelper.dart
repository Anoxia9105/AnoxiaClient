import 'dart:io';

import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:anoxia/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:window_manager/window_manager.dart' as desktop;

import '../../framework/logs/talker.dart';

class NotificationHelper {
  NotificationHelper._internal();
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Android
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS & macOS
    final darwin = DarwinInitializationSettings();

    // 3. Linux
    final linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    String? imagePath;
    try {
      imagePath = await getIconPath();
    } catch (e) {
      log.error("获取图标失败: $e");
    }
    // 注意：guid 建议你自己生成一个唯一的，appName 改成你的应用名
    final windows = WindowsInitializationSettings(
      appName: 'Anoxia',
      appUserModelId: 'com.anoxia.cn',
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      iconPath: imagePath,
    );

    final settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTapNotification,
    );
  }

  Future<String> getIconPath() async {
    // 获取应用文档目录或临时目录
    final directory = await getApplicationSupportDirectory();
    final filePath = p.join(directory.path, 'notification_icon.png');
    final file = File(filePath);

    // 如果文件不存在，从 Assets 复制过去
    if (!await file.exists()) {
      final byteData = await rootBundle.load(Assets.images.appIconPng.path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    log.info("获取图标成功: ${file.path}");
    return file.path;
  }

  void _onTapNotification(NotificationResponse response) {
    final String? roomId = response.payload;

    if (roomId != null) {
      log.info("用户点击通知，准备跳转房间: $roomId");

      // 直接使用全局容器进行 Provider 操作
      // 1. 设置当前活跃房间
      globalContainer.read(activeRoomIdProvider.notifier).setActive(roomId);

      // 2. 切换侧边栏/布局索引（假设 layoutControllerProvider 控制主页 Tab）
      globalContainer.read(layoutControllerProvider.notifier).setIndex(0);

      // 3. 桌面端特有：唤醒并聚焦窗口，防止点击了通知但窗口还在后台
      _ensureWindowActive();
    }
  }

  void _ensureWindowActive() async {
    try {
      if (await desktop.windowManager.isMinimized()) {
        await desktop.windowManager.restore();
      }
      await desktop.windowManager.show();
      await desktop.windowManager.focus();
    } catch (e) {
      log.error("唤醒窗口失败: $e");
    }
  }

  /// 发送通知的方法
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (await windowManager.isVisible()) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('main_channel', 'Main'),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
