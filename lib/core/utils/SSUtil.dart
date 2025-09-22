import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SSUtil {
  // ---------------- 单例实现 ----------------
  SSUtil._internal();

  static final SSUtil _instance = SSUtil._internal();

  factory SSUtil() => _instance;

  static SSUtil get instance => _instance;

  // flutter_secure_storage 实例（只初始化一次）
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// 写入数据并设置有效期（单位：秒）
  Future<void> write({
    required String key,
    required String value,
    Duration? expiry,
  }) async {
    await _storage.write(key: key, value: value);
    if (expiry != null) {
      final expiryTime = DateTime.now().add(expiry);
      await _storage.write(
        key: '${key}_expiry',
        value: expiryTime.toIso8601String(),
      );
    }
  }

  /// 读取数据（自动判断是否过期）
  Future<String?> read({required String key}) async {
    final expiryStr = await _storage.read(key: '${key}_expiry');
    if (expiryStr != null) {
      final expiryTime = DateTime.tryParse(expiryStr);
      if (expiryTime != null && DateTime.now().isAfter(expiryTime)) {
        // 已过期 → 删除数据
        await delete(key: key);
        return null;
      }
    }
    return await _storage.read(key: key);
  }

  /// 删除数据
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
    await _storage.delete(key: '${key}_expiry');
  }

  /// 清空所有数据
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
