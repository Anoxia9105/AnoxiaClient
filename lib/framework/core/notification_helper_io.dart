import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_manager/window_manager.dart' as desktop;

import 'package:anoxia/framework/logs/debug_log.dart';

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

  static const MethodChannel _taskbarBadgeChannel = MethodChannel(
    'anoxia/taskbar_badge',
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String roomId)? _onOpenRoom;
  FutureOr<void> Function(String actionId, Map<String, dynamic> payload)?
  _onCallAction;

  /// 「更新已就绪」通知点击回调（由 main.dart 注入，触发安装）
  void Function()? _onUpdateInstall;

  static const String callAcceptAction = 'call_accept';
  static const String callRejectAction = 'call_reject';
  static const String _incomingCallCategory = 'incoming_call';

  void configure({
    required void Function(String roomId) onOpenRoom,
    FutureOr<void> Function(String actionId, Map<String, dynamic> payload)?
    onCallAction,
    void Function()? onUpdateInstall,
  }) {
    _onOpenRoom = onOpenRoom;
    _onCallAction = onCallAction;
    _onUpdateInstall = onUpdateInstall;
  }

  /// 初始化通知插件
  ///
  /// 配置各平台的初始化设置，包括 Android、iOS、macOS、Linux、Windows
  Future<void> init() async {
    await _pruneAvatarCache();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _incomingCallCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              callAcceptAction,
              'notification_call_accept'.tr(),
              options: const <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(callRejectAction, 'notification_call_reject'.tr()),
          ],
        ),
      ],
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    String? imagePath;
    try {
      imagePath = await getIconPath();
    } catch (e) {
      debugLog('获取图标失败: $e');
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

  Future<bool> _ensureNotificationPermission() async {
    if (!DeviceUtil.isRealMobile()) return true;
    final result = await appPermissionService.request(Permission.notification);
    if (result == AppPermissionResult.granted) return true;
    debugLog('通知权限不可用，本次通知已跳过: $result');
    return false;
  }

  /// 主动申请通知权限。
  ///
  /// 与 Web 实现保持同名 API，便于设置页等共享代码直接调用而无需区分平台。
  Future<bool> requestPermission() => _ensureNotificationPermission();

  /// 当前通知权限是否已授予。
  ///
  /// 查询型接口：只读取当前授权状态，**绝不**触发系统权限弹窗。
  /// 桌面端无需通知权限，恒为 true；移动端读取 [Permission.notification] 当前状态。
  Future<bool> isPermissionGranted() async {
    if (!DeviceUtil.isRealMobile()) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 平台是否支持通知（原生端恒为 true，与 Web 实现保持同名 API）。
  bool get isSupported => true;

  /// 权限是否被永久拒绝（原生端由系统设置托管，这里恒为 false）。
  bool get isPermissionDenied => false;

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
              const maxAvatarBytes = 2 * 1024 * 1024;
              if (resp.contentLength > maxAvatarBytes) return null;
              final bytes = BytesBuilder(copy: false);
              var total = 0;
              await for (final chunk in resp) {
                total += chunk.length;
                if (total > maxAvatarBytes) return null;
                bytes.add(chunk);
              }
              await file.writeAsBytes(bytes.takeBytes(), flush: true);
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
      debugLog('解析通知头像失败: $e');
    }

    return null;
  }

  Future<void> _pruneAvatarCache() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final files = await dir
          .list()
          .where(
            (entry) =>
                entry is File && entry.path.contains('notification_avatar_'),
          )
          .cast<File>()
          .toList();
      if (files.length <= 50) return;
      final byNewest = <({File file, DateTime modified})>[];
      for (final file in files) {
        byNewest.add((file: file, modified: await file.lastModified()));
      }
      byNewest.sort((a, b) => b.modified.compareTo(a.modified));
      for (final entry in byNewest.skip(50)) {
        await entry.file.delete();
      }
    } catch (e) {
      debugLog('清理通知头像缓存失败: $e');
    }
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
      debugLog('判断窗口状态失败，降级为发送通知: $e');
    }
    return true;
  }

  /// 处理通知点击
  void _onTapNotification(NotificationResponse response) {
    final String? roomId = response.payload;

    if (roomId != null && roomId.startsWith('{')) {
      try {
        final decoded = jsonDecode(roomId);
        if (decoded is Map && decoded['kind'] == 'update_install') {
          // 「更新已就绪」通知点击：拉起安装器（回调由 main.dart 注入）
          _onUpdateInstall?.call();
          if (DeviceUtil.isRealDesktop()) {
            unawaited(_ensureWindowActive());
          }
          return;
        }
        if (decoded is Map && decoded['kind'] == 'incoming_call') {
          final payload = Map<String, dynamic>.from(decoded);
          final actionId =
              payload['actionId']?.toString() ?? response.actionId ?? '';
          if (actionId == callAcceptAction || actionId == callRejectAction) {
            unawaited(
              Future.sync(() => _onCallAction?.call(actionId, payload)),
            );
          } else {
            final callRoomId = payload['roomId']?.toString();
            if (callRoomId != null && callRoomId.isNotEmpty) {
              _onOpenRoom?.call(callRoomId);
            }
          }
          if (DeviceUtil.isRealDesktop()) {
            unawaited(_ensureWindowActive());
          }
          return;
        }
      } catch (e) {
        debugLog('无法解析通话通知载荷: $e');
      }
    }

    if (roomId != null) {
      _onOpenRoom?.call(roomId);

      // 仅桌面端需要主动唤醒窗口；移动端调用会触发 MissingPluginException。
      if (DeviceUtil.isRealDesktop()) {
        _ensureWindowActive();
      }
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
      debugLog('唤醒窗口失败: $e');
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
    if (!await _ensureNotificationPermission()) return;

    /// 桌面端如果窗口可见且聚焦，且未强制发送，则不显示通知
    if (DeviceUtil.isRealDesktop() && !await _shouldNotify(force: force)) {
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

  /// 显示带有接听/拒绝动作的强制来电通知。
  Future<void> showIncomingCall({
    required Map<String, dynamic> payload,
    required String title,
    required String body,
    String? avatarUrl,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    if (!await _ensureNotificationPermission()) return;

    final notificationId = incomingCallNotificationId(
      payload['inviteId']?.toString() ?? payload['roomId']?.toString() ?? '',
    );
    final encodedPayload = jsonEncode(<String, dynamic>{
      ...payload,
      'kind': 'incoming_call',
    });

    final avatarUri = await _resolveWindowsAvatarUri(avatarUrl);
    final windowsImages = avatarUri == null
        ? const <WindowsImage>[]
        : <WindowsImage>[
            WindowsImage(
              avatarUri,
              altText: title,
              placement: WindowsImagePlacement.appLogoOverride,
              crop: WindowsImageCrop.circle,
            ),
          ];

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'incoming_call_channel',
        'notification_incoming_call_channel'.tr(),
        channelDescription: 'notification_incoming_call_channel_desc'.tr(),
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            callRejectAction,
            'notification_call_reject'.tr(),
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            callAcceptAction,
            'notification_call_accept'.tr(),
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: _incomingCallCategory,
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        categoryIdentifier: _incomingCallCategory,
        presentAlert: true,
        presentSound: true,
      ),
      windows: WindowsNotificationDetails(
        duration: WindowsNotificationDuration.long,
        scenario: WindowsNotificationScenario.incomingCall,
        images: windowsImages,
        actions: <WindowsAction>[
          WindowsAction(
            content: 'notification_call_accept'.tr(),
            arguments: jsonEncode(<String, dynamic>{
              ...payload,
              'kind': 'incoming_call',
              'actionId': callAcceptAction,
            }),
          ),
          WindowsAction(
            content: 'notification_call_reject'.tr(),
            arguments: jsonEncode(<String, dynamic>{
              ...payload,
              'kind': 'incoming_call',
              'actionId': callRejectAction,
            }),
          ),
        ],
      ),
    );

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: encodedPayload,
    );
  }

  Future<void> cancelIncomingCall(String inviteId) async {
    if (kIsWeb || inviteId.isEmpty) return;
    await _ensureInitialized();
    await _plugin.cancel(id: incomingCallNotificationId(inviteId));
  }

  int incomingCallNotificationId(String inviteId) {
    return 0x3fffffff & inviteId.hashCode;
  }

  /// 更新系统未读角标（Android/iOS/macOS App 图标、Windows 任务栏）
  ///
  /// [count] 角标数量，<=0 时移除角标
  Future<void> updateUnreadBadge(int count) async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        await _taskbarBadgeChannel.invokeMethod<void>('updateBadge', {
          'count': count < 0 ? 0 : count,
        });
      } catch (e) {
        debugLog('更新 Windows 任务栏角标失败: $e');
      }
      return;
    }

    final isAppBadgePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (!isAppBadgePlatform) return;

    try {
      final supported = await AppBadgePlus.isSupported();
      if (!supported) return;
      await AppBadgePlus.updateBadge(count <= 0 ? 0 : count);
    } catch (e) {
      debugLog('更新应用角标失败: $e');
    }
  }
}
