import 'package:notepadclient/framework/provider/auth/auth_state_provider.dart';
import 'package:notepadclient/framework/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../network/TokenManager.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  void build() {}

  /// 自动登录
  Future<void> autoLogin() async {
    final token = await TokenManager.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await ref.read(userInfoProvider.future);
      ref.read(authStateProvider.notifier).login();
    } catch (e) {
      await TokenManager.instance.clearToken();
      ref.read(authStateProvider.notifier).logout();
    }
  }

  Future<void> login(
    String username,
    String password,
    String code,
    String uuid,
  ) async {
    final repo = ref.read(authServiceProvider);
    final ok = await repo.login(username, password, code, uuid);
    if (ok) {
      // 刷新用户信息
      ref.invalidate(userInfoProvider);
      ref.read(authStateProvider.notifier).login();
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authServiceProvider);
    await repo.logout();
    ref.read(authStateProvider.notifier).logout();
  }
}
