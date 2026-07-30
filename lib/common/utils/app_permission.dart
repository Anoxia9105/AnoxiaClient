/// 应用权限检查和请求工具。
///
/// 提供统一的权限请求、状态检查以及系统设置跳转能力，
/// 支持 iOS 和 Android 平台差异处理。
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限请求结果枚举。
enum AppPermissionResult {
  /// 权限已授予。
  granted,

  /// 权限被拒绝。
  denied,

  /// 需要跳转到系统设置页面手动授权。
  settingsRequired,
}

/// 权限网关接口，抽象权限的查询、请求和设置跳转。
abstract interface class AppPermissionGateway {
  /// 查询指定权限的当前状态。
  Future<PermissionStatus> status(Permission permission);

  /// 请求指定权限。
  Future<PermissionStatus> request(Permission permission);

  /// 打开系统设置页面。
  Future<bool> openSettings();
}

/// 基于 [permission_handler] 的权限网关实现。
class PermissionHandlerGateway implements AppPermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<PermissionStatus> status(Permission permission) => permission.status;

  @override
  Future<PermissionStatus> request(Permission permission) =>
      permission.request();

  @override
  Future<bool> openSettings() => openAppSettings();
}

/// Runtime permissions are deliberately checked at the point of use.
/// A normal denial is never cached, so the next user action requests again.
class AppPermissionService {
  const AppPermissionService({this.gateway = const PermissionHandlerGateway()});

  /// 权限网关实例。
  final AppPermissionGateway gateway;

  /// 请求指定权限并返回结果。
  ///
  /// [permission] 需要请求的权限类型。
  /// [acceptLimited] 是否接受受限权限（如 iOS 的照片部分访问权限）。
  Future<AppPermissionResult> request(
    Permission permission, {
    bool acceptLimited = false,
  }) async {
    try {
      final current = await gateway.status(permission);
      if (_isAccepted(current, acceptLimited: acceptLimited)) {
        return AppPermissionResult.granted;
      }
      if (_requiresSettings(current)) {
        return AppPermissionResult.settingsRequired;
      }

      final requested = await gateway.request(permission);
      if (_isAccepted(requested, acceptLimited: acceptLimited)) {
        return AppPermissionResult.granted;
      }
      return _requiresSettings(requested)
          ? AppPermissionResult.settingsRequired
          : AppPermissionResult.denied;
    } catch (_) {
      return AppPermissionResult.denied;
    }
  }

  /// 打开系统设置页面。
  Future<bool> openSettings() => gateway.openSettings();

  static bool _isAccepted(
    PermissionStatus status, {
    required bool acceptLimited,
  }) {
    return status.isGranted || (acceptLimited && status.isLimited);
  }

  static bool _requiresSettings(PermissionStatus status) {
    return status.isPermanentlyDenied || status.isRestricted;
  }
}

/// 全局权限服务实例。
const appPermissionService = AppPermissionService();

/// 确保应用拥有指定权限，必要时弹出系统设置引导对话框。
///
/// [context] 当前构建上下文，用于显示对话框。
/// [permission] 需要确保的权限类型。
/// [permissionName] 权限名称，用于对话框中的提示文案。
/// [acceptLimited] 是否接受受限权限。
/// 返回 `true` 表示权限已授予。
Future<bool> ensureAppPermission(
  BuildContext context,
  Permission permission, {
  required String permissionName,
  bool acceptLimited = false,
}) async {
  final result = await appPermissionService.request(
    permission,
    acceptLimited: acceptLimited,
  );
  if (result == AppPermissionResult.granted) return true;
  if (result != AppPermissionResult.settingsRequired || !context.mounted) {
    return false;
  }

  final shouldOpenSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('permission_required_title'.tr(args: [permissionName])),
      content: Text('permission_settings_required'.tr(args: [permissionName])),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('dialog_cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('permission_go_to_settings'.tr()),
        ),
      ],
    ),
  );
  if (shouldOpenSettings == true) await appPermissionService.openSettings();
  return false;
}

/// 确保相册/存储写入权限，自动处理 iOS 和 Android 平台差异。
///
/// iOS 使用照片部分访问权限，Android 10+ 通过 MediaStore 写入无需存储权限。
Future<bool> ensureGalleryWritePermission(BuildContext context) async {
  if (Platform.isIOS) {
    return ensureAppPermission(
      context,
      Permission.photosAddOnly,
      permissionName: '相册',
      acceptLimited: true,
    );
  }
  if (Platform.isAndroid) {
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    // Android 10+ writes through MediaStore and needs no storage permission.
    if (sdkInt >= 29) return true;
    if (!context.mounted) return false;
    return ensureAppPermission(
      context,
      Permission.storage,
      permissionName: '存储',
    );
  }
  return true;
}
