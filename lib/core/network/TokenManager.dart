// token_manager.dart
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';

class TokenManager {
  TokenManager._internal();
  static final TokenManager instance = TokenManager._internal();

  String? _cachedToken;

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await SSUtil.instance.read(key: StorageKeys.accessToken);
    return _cachedToken;
  }

  Future<void> setToken(String token, {Duration? expiry}) async {
    _cachedToken = token;
    await SSUtil.instance.write(
      key: StorageKeys.accessToken,
      value: token,
      expiry: expiry,
    );
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await SSUtil.instance.delete(key: StorageKeys.accessToken);
  }
}
