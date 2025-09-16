import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/StorageKeys.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<void> deleteAccessToken() => _storage.delete(key: StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<void> clear() => _storage.deleteAll();
}
