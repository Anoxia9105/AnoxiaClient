import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/shims/secure_context_shim.dart';
import '../constants/storage_keys.dart';

/// SecureStorage 工具类
///
/// 提供加密的安全存储能力，用于存放敏感数据（如 Token）。
/// 与 [SPUtil] 的区别：此工具在安全上下文优先使用 AES 加密存储，数据更安全。
///
/// Web 兼容：`flutter_secure_storage` Web 实现仅在安全上下文
///（https / localhost / 127.0.0.1）下可用，`http://公网IP` 会抛
/// `Unsupported operation: FlutterSecureStorageWeb only works in secure contexts`。
/// 非安全上下文自动降级到 SharedPreferences（localStorage），保证一键脚本
/// 默认的 IP+HTTP 部署也能登录；切回 HTTPS 后仍能读到降级存储的数据。
class SSUtil {
  SSUtil._();

  static final SSUtil _instance = SSUtil._();
  static SSUtil get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  SharedPreferences? _fallbackPrefs;

  /// 降级存储实例（懒加载，不依赖 SPUtil 初始化顺序）。
  Future<SharedPreferences?> _fallback() async {
    try {
      return _fallbackPrefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readFallback(String key) async {
    final prefs = await _fallback();
    try {
      return prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeFallback(String key, String value) async {
    final prefs = await _fallback();
    try {
      await prefs?.setString(key, value);
    } catch (_) {
      // 降级存储写入失败也不向上传播，避免红屏。
    }
  }

  /// 读取字符串
  Future<String?> read({required String key}) async {
    // 非安全上下文：直接走降级存储，不触碰 FlutterSecureStorage（必抛）。
    if (!SecureContext.isSecureContext) {
      return _readFallback(key);
    }
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (_) {
      // 加密存储不可用时继续走降级读取（兼容 http 下写入的数据）。
    }
    return _readFallback(key);
  }

  /// 写入字符串
  Future<void> write({required String key, required String value}) async {
    // 安全上下文双写：加密存储为主，降级存储为镜像，保证 http/https 互切不断登。
    if (SecureContext.isSecureContext) {
      try {
        await _storage.write(key: key, value: value);
      } catch (_) {
        // 加密存储失败时仍继续写降级存储。
      }
    }
    await _writeFallback(key, value);
  }

  /// 删除指定键
  Future<void> delete({required String key}) async {
    if (SecureContext.isSecureContext) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // 忽略，由降级删除兜底。
      }
    }
    try {
      final prefs = await _fallback();
      await prefs?.remove(key);
    } catch (_) {
      // 删除失败不抛异常。
    }
  }

  /// 删除所有数据
  Future<void> deleteAll() async {
    if (SecureContext.isSecureContext) {
      try {
        await _storage.deleteAll();
      } catch (_) {
        // 忽略，由降级清理兜底。
      }
    }
    // 注意：降级存储与 SPUtil 共用 SharedPreferences 命名空间，
    // 这里不能 clear() 全量，否则会误删主题/设置等偏好；仅清理经
    // SSUtil 写入过的敏感键（与登出按 key 删除保持一致）。
    try {
      final prefs = await _fallback();
      for (final key in [
        StorageKeys.accessToken,
        StorageKeys.sysUser,
        StorageKeys.secret,
        StorageKeys.lastLoginUserId,
        StorageKeys.savedAccounts,
      ]) {
        await prefs?.remove(key);
      }
    } catch (_) {
      // 清理失败不抛异常。
    }
  }

  /// 读取 JSON 对象
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    final raw = await read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// 写入 JSON 对象
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    await write(key: key, value: jsonEncode(value));
  }
}
