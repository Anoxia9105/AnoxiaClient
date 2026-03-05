import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../network/TokenManager.dart';

part 'token_provider.g.dart';

/// Token Provider - 用于在内存中缓存 token
/// 登录成功后更新，登出时清空
/// 避免每次请求都从 TokenManager 读取
@Riverpod(keepAlive: true)
class TokenCache extends _$TokenCache {
  @override
  String? build() {
    // 初始为 null，由 AuthController 在登录/自动恢复时设置
    return null;
  }

  /// 设置 token（登录成功时调用）
  void setToken(String token) {
    state = token;
  }

  /// 清除 token（登出时调用）
  void clearToken() {
    state = null;
  }

  /// 从 TokenManager 恢复 token（仅在应用启动时调用）
  Future<void> restoreToken() async {
    final token = await TokenManager.instance.getToken();
    if (token != null && token.isNotEmpty) {
      state = token;
    }
  }
}
