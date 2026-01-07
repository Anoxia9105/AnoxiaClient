// SSUtil.dart
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

class SSUtil {
  SSUtil._internal();

  static final SSUtil instance = SSUtil._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 读取（带过期判断）
  Future<String?> read({required String key}) async {
    try {
      final expiryStr = await _storage.read(key: '${key}_expiry');
      if (expiryStr != null) {
        final expiryTime = DateTime.tryParse(expiryStr);
        if (expiryTime != null && DateTime.now().isAfter(expiryTime)) {
          // 过期则删除并返回空
          await delete(key: key);
          return null;
        }
      }
      return await _storage.read(key: key);
    } catch (e) {
      // 解密失败等异常兜底
      print('SSUtil.read 失败: $e');
      return null;
    }
  }

  // 写入（可选过期时间）
  Future<void> write({
    required String key,
    required String value,
    Duration? expiry,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      if (expiry != null) {
        await _storage.write(
          key: '${key}_expiry',
          value: DateTime.now().add(expiry).toIso8601String(),
        );
      } else {
        await _storage.delete(key: '${key}_expiry');
      }
    } catch (e) {
      print('SSUtil.write 失败: $e');
      rethrow;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      await _storage.delete(key: '${key}_expiry');
    } catch (e) {
      print('SSUtil.delete 失败: $e');
      // 删除失败也不抛出，避免崩溃
    }
  }

  // Windows 文件健康检查（可选，在启动时调用）
  Future<void> ensureHealthy({String? windowsPath}) async {
    if (windowsPath == null) return;
    final file = File(windowsPath);
    if (await file.exists()) {
      try {
        final raf = await file.open(mode: FileMode.append);
        await raf.close();
      } catch (e) {
        print('检测到损坏的 secure_storage 文件，尝试删除: $e');
        try {
          await file.delete();
        } catch (e2) {
          print('删除损坏文件失败: $e2');
        }
      }
    }
  }
}
