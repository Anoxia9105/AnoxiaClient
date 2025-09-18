import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';

/// TokenStorage
/// 用于安全存储和读取 AccessToken / RefreshToken
/// 单例模式：全局唯一实例，方便全局调用
class TokenStorage {
  // 私有构造函数
  TokenStorage._internal();

  // 静态单例实例
  static final TokenStorage _instance = TokenStorage._internal();

  // 工厂构造函数，返回同一个实例
  factory TokenStorage() => _instance;

  // Flutter Secure Storage 实例（安全存储）
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 保存 AccessToken
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  /// 读取 AccessToken
  Future<String?> readAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  /// 删除 AccessToken
  Future<void> deleteAccessToken() =>
      _storage.delete(key: StorageKeys.accessToken);

  /// 保存 RefreshToken
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  /// 读取 RefreshToken
  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  /// 清空所有 Token
  Future<void> clear() => _storage.deleteAll();
}
