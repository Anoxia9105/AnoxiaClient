import 'package:flutter/material.dart';

/// 本地存储键值常量
///
/// 集中管理应用本地存储（SharedPreferences）的所有键名
class StorageKeys {
  /// 用户访问 Token
  static const String accessToken = 'ACCESS_TOKEN';

  /// 用户信息
  static const String sysUser = 'SYS_USER';

  /// 密钥（用于加密等）
  static const String secret = 'SECRET';

  /// 蓝牙权限是否已申请（布尔值，true/false）
  static const String kBluetoothPermissionRequestedKey =
      'bluetooth_permission_requested_v1';
}
