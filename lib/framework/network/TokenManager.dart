import '../../common/constants/StorageKeys.dart';
import '../../common/utils/SSUtil.dart';

/// Token 管理器
///
/// 负责 Token 的读取、写入和清除操作。
/// 采用内存缓存 + 本地持久化的双层策略，减少 IO 操作。
class TokenManager {
  TokenManager._internal();

  static final TokenManager instance = TokenManager._internal();

  String? _cachedToken;

  /// 获取 Token
  ///
  /// 优先返回内存缓存，首次访问时从本地存储读取。
  /// 读取后缓存到内存，后续调用直接返回缓存值。
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    _cachedToken = await SSUtil.instance.read(key: StorageKeys.accessToken);
    return _cachedToken;
  }

  /// 保存 Token
  ///
  /// 同步更新内存缓存，异步写入本地持久化存储。
  Future<void> setToken(String token) async {
    _cachedToken = token;
    await SSUtil.instance.write(
      key: StorageKeys.accessToken,
      value: token,
    );
  }

  /// 清除 Token
  ///
  /// 同步清空内存缓存，异步删除本地存储。
  Future<void> clearToken() async {
    _cachedToken = null;
    await SSUtil.instance.delete(key: StorageKeys.accessToken);
  }
}
