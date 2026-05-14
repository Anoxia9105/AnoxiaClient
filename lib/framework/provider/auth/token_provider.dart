import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../network/TokenManager.dart';

part 'token_provider.g.dart';

/// Token 内存缓存 Provider
///
/// 登录成功后更新，登出时清空。
/// 采用 keepAlive 保持常驻，避免重复初始化。
/// 与 [TokenManager] 的区别：此 Provider 提供响应式状态，
/// [TokenManager] 提供持久化能力。
@Riverpod(keepAlive: true)
class TokenCache extends _$TokenCache {
  @override
  String? build() {
    // 初始为 null，由 AuthController 在登录/自动恢复时设置
    return null;
  }

  /// 设置 Token
  ///
  /// 登录成功时调用，同时更新内存状态
  void setToken(String token) {
    state = token;
  }

  /// 清除 Token
  ///
  /// 登出时调用，清空内存缓存
  void clearToken() {
    state = null;
  }

  /// 从 [TokenManager] 恢复 Token
  ///
  /// 仅在应用冷启动时调用一次
  Future<void> restoreToken() async {
    final token = await TokenManager.instance.getToken();
    if (token != null && token.isNotEmpty) {
      state = token;
    }
  }
}
