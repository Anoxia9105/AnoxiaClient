import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SecureStorage 工具类
///
/// 提供加密的安全存储能力，用于存放敏感数据（如 Token）。
/// 与 [SPUtil] 的区别：此工具使用 AES 加密存储，数据更安全。
class SSUtil {
  SSUtil._();

  static final SSUtil _instance = SSUtil._();
  static SSUtil get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 读取字符串
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  /// 写入字符串
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// 删除指定键
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// 删除所有数据
  Future<void> deleteAll() async {
    await _storage.deleteAll();
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
