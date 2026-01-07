import '../../common/constants/StorageKeys.dart';
import '../../common/utils/SSUtil.dart';

class TokenManager {
  TokenManager._internal();
  static final TokenManager instance = TokenManager._internal();

  String? _cachedToken;

  /// 获取 token（只在第一次 await IO）
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    // 第一次从本地读取
    _cachedToken = await SSUtil.instance.read(key: StorageKeys.accessToken);
    return _cachedToken;
  }

  /// 设置 token（同步更新缓存 + 写入本地）
  Future<void> setToken(String token) async {
    _cachedToken = token;
    await SSUtil.instance.write(
      key: StorageKeys.accessToken,
      value: token,
    );
  }

  /// 清除 token（同步清空缓存 + 删除本地）
  Future<void> clearToken() async {
    _cachedToken = null;
    await SSUtil.instance.delete(key: StorageKeys.accessToken);
  }
}
