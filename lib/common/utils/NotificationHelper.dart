import 'dart:io';

import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:anoxia/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_new_badger/flutter_new_badger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_manager/window_manager.dart' as desktop;

import '../../framework/logs/talker.dart';

class NotificationHelper {
  NotificationHelper._internal();
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

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
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<String> getIconPath() async {
    // 获取应用文档目录或临时目录
    final directory = await getApplicationSupportDirectory();
  final filePath = '${directory.path}${Platform.pathSeparator}notification_icon.png';
    final file = File(filePath);

    // 如果文件不存在，从 Assets 复制过去
    if (!await file.exists()) {
      final byteData = await rootBundle.load(Assets.images.appIconPng.path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    log.info("获取图标成功: ${file.path}");
    return file.path;
  }

  Future<Uri?> _resolveWindowsAvatarUri(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    try {
      // 本地文件
      final asFile = File(avatarUrl);
      if (await asFile.exists()) {
        return Uri.file(asFile.path, windows: true);
      }

      // file:///...
      final uri = Uri.tryParse(avatarUrl);
      if (uri != null && uri.scheme == 'file') {
        final f = File.fromUri(uri);
        if (await f.exists()) {
          return Uri.file(f.path, windows: true);
        }
      }

      // 网络头像：下载到本地，再用 file URI（兼容非 MSIX）
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final dir = await getApplicationSupportDirectory();
    final lastDot = uri.path.lastIndexOf('.');
    final ext =
      (lastDot != -1 && lastDot < uri.path.length - 1) ? uri.path.substring(lastDot) : '.png';
    final filePath =
      '${dir.path}${Platform.pathSeparator}notification_avatar_${avatarUrl.hashCode}$ext';
        final file = File(filePath);

        if (!await file.exists()) {
          final client = HttpClient();
          try {
            final req = await client.getUrl(uri);
            final resp = await req.close();
            if (resp.statusCode == 200) {
              final bytes = await resp.fold<List<int>>(
                <int>[],
                (prev, e) => prev..addAll(e),
              );
              await file.writeAsBytes(bytes, flush: true);
            }
          } finally {
            client.close(force: true);
          }
        }

        if (await file.exists()) {
          return Uri.file(file.path, windows: true);
        }
      }
    } catch (e) {
      log.error('解析通知头像失败: $e');
    }

    return null;
  }

  Future<bool> _shouldNotify({bool force = false}) async {
    if (force) return true;

    try {
      final visible = await windowManager.isVisible();
      final focused = await windowManager.isFocused();
      final minimized = await windowManager.isMinimized();

      // 只有“可见+聚焦+未最小化”才不通知
      if (visible && focused && !minimized) {
        return false;
      }
    } catch (e) {
      log.error('判断窗口状态失败，降级为发送通知: $e');
    }
    return true;
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
    String? avatarUrl,
    bool force = false,
  }) async {
    // Web 不支持本地通知插件，直接跳过
    if (kIsWeb) return;

    // 统一在 helper 内懒初始化，避免调用方关心平台与初始化时机
    await _ensureInitialized();

    if (!await _shouldNotify(force: force)) {
      return;
    }

    WindowsNotificationDetails? windowsDetails;
    final avatarUri = await _resolveWindowsAvatarUri(avatarUrl);
    if (avatarUri != null) {
      windowsDetails = WindowsNotificationDetails(
        images: [
          WindowsImage(
            avatarUri,
            altText: 'avatar',
            placement: WindowsImagePlacement.appLogoOverride,
            crop: WindowsImageCrop.circle,
          ),
        ],
      );
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails('main_channel', 'Main'),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      windows: windowsDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// 同步手机桌面 App 图标角标（Android/iOS）
  Future<void> updateAppIconBadge(int count) async {
    if (kIsWeb) return;
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return;

    try {
      if (count <= 0) {
        await FlutterNewBadger.removeBadge();
      } else {
        await FlutterNewBadger.setBadge(count);
      }
    } catch (e) {
      log.warning('更新桌面角标失败: $e');
    }
  }
}
