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

/// 通知辅助类
///
/// 封装桌面和移动端的本地通知功能，支持：
/// - 消息推送通知
/// - 点击通知跳转房间
/// - 头像显示
/// - App 图标角标更新
class NotificationHelper {
  NotificationHelper._internal();
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化通知插件
  ///
  /// 配置各平台的初始化设置，包括 Android、iOS、macOS、Linux、Windows
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    String? imagePath;
    try {
      imagePath = await getIconPath();
    } catch (e) {
      log.error('获取图标失败: $e');
    }

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

  /// 获取通知图标路径
  ///
  /// Windows 通知需要本地文件路径，先从 Assets 复制到应用目录
  Future<String> getIconPath() async {
    final directory = await getApplicationSupportDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}notification_icon.png';
    final file = File(filePath);

    if (!await file.exists()) {
      final byteData = await rootBundle.load(Assets.images.appIconPng.path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    log.info('获取图标成功: ${file.path}');
    return file.path;
  }

  /// 解析 Windows 通知头像 URI
  ///
  /// 支持本地文件、file:// 协议和网络图片（下载到本地）
  Future<Uri?> _resolveWindowsAvatarUri(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    try {
      final asFile = File(avatarUrl);
      if (await asFile.exists()) {
        return Uri.file(asFile.path, windows: true);
      }

      final uri = Uri.tryParse(avatarUrl);
      if (uri != null && uri.scheme == 'file') {
        final f = File.fromUri(uri);
        if (await f.exists()) {
          return Uri.file(f.path, windows: true);
        }
      }

      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final dir = await getApplicationSupportDirectory();
        final lastDot = uri.path.lastIndexOf('.');
        final ext = (lastDot != -1 && lastDot < uri.path.length - 1)
            ? uri.path.substring(lastDot)
            : '.png';
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

  /// 判断是否应该发送通知
  ///
  /// 当窗口可见且聚焦时跳过通知，[force] 强制发送
  Future<bool> _shouldNotify({bool force = false}) async {
    if (force) return true;

    try {
      final visible = await windowManager.isVisible();
      final focused = await windowManager.isFocused();
      final minimized = await windowManager.isMinimized();

      if (visible && focused && !minimized) {
        return false;
      }
    } catch (e) {
      log.error('判断窗口状态失败，降级为发送通知: $e');
    }
    return true;
  }

  /// 处理通知点击
  void _onTapNotification(NotificationResponse response) {
    final String? roomId = response.payload;

    if (roomId != null) {
      log.info('用户点击通知，准备跳转房间: $roomId');

      globalContainer.read(activeRoomIdProvider.notifier).setActive(roomId);
      globalContainer.read(layoutControllerProvider.notifier).setIndex(0);

      _ensureWindowActive();
    }
  }

  /// 确保窗口处于激活状态
  Future<void> _ensureWindowActive() async {
    try {
      if (await desktop.windowManager.isMinimized()) {
        await desktop.windowManager.restore();
      }
      await desktop.windowManager.show();
      await desktop.windowManager.focus();
    } catch (e) {
      log.error('唤醒窗口失败: $e');
    }
  }

  /// 发送通知
  ///
  /// [id] 通知唯一标识
  /// [title] 通知标题
  /// [body] 通知内容
  /// [payload] 携带数据（点击时透传）
  /// [avatarUrl] 头像 URL（Windows 支持）
  /// [force] 是否强制发送（忽略窗口焦点状态）
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? avatarUrl,
    bool force = false,
  }) async {
    if (kIsWeb) return;

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
      android: const AndroidNotificationDetails('main_channel', 'Main'),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
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

  /// 更新 App 图标角标（Android/iOS）
  ///
  /// [count] 角标数量，<=0 时移除角标
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
