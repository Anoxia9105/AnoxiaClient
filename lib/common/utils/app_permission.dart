import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionResult { granted, denied, settingsRequired }

abstract interface class AppPermissionGateway {
  Future<PermissionStatus> status(Permission permission);
  Future<PermissionStatus> request(Permission permission);
  Future<bool> openSettings();
}

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

  final AppPermissionGateway gateway;

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

const appPermissionService = AppPermissionService();

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
