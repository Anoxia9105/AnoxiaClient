import 'package:notepadclient/framework/provider/auth/auth_state_provider.dart';
import 'package:notepadclient/framework/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  void build() {
    // 初始化时不执行任何操作，由 AppInitializer 控制
    log.info("🔧 AuthController 初始化完成");
  }

  /// 自动登录
  Future<void> autoLogin() async {
    log.info("[AuthController] 开始自动登录流程...");

    final token = await TokenManager.instance.getToken();
    log.info("[AuthController] Token状态: ${token != null ? "存在" : "不存在"}");

    if (token == null || token.isEmpty) {
      log.info("[AuthController] 无Token，设置为未登录状态");
      ref.read(authStateProvider.notifier).logout();
      return;
    }

    try {
      log.info("[AuthController] 开始验证Token并获取用户信息...");

      // 直接使用 AuthService，避免依赖 userInfoProvider
      final authService = ref.read(authServiceProvider);
      final user = await authService.getUserInfo();

      log.info("[AuthController] 用户信息获取成功: ${user.nickName}");

      // 更新认证状态
      ref.read(authStateProvider.notifier).login(user);
      log.info("[AuthController] ✅ 自动登录成功");
    } catch (e, stack) {
      log.error("[AuthController] ❌ 自动登录失败", e, stack);
      // 清除无效的Token
      // await TokenManager.instance.clearToken();

      // 设置为未登录状态
      ref.read(authStateProvider.notifier).setError("自动登录失败");
    }
  }

  Future<void> login(
    String username,
    String password,
    String code,
    String uuid,
  ) async {
    log.info("[AuthController] 开始手动登录...");

    try {
      final repo = ref.read(authServiceProvider);
      String token = await repo.login(username, password, code, uuid);

      if (token.isNotEmpty) {
        log.info("[AuthController] 登录成功，获取用户信息...");
        final user = await repo.getUserInfo();
        ref.read(authStateProvider.notifier).login(user);
        log.info("[AuthController] ✅ 手动登录完成");
      }
    } catch (e, stack) {
      log.error("[AuthController] ❌ 手动登录失败", e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    log.info("[AuthController] 开始登出...");

    try {
      final repo = ref.read(authServiceProvider);
      await repo.logout();
      ref.read(authStateProvider.notifier).logout();
      log.info("[AuthController] ✅ 登出完成");
    } catch (e, stack) {
      log.error("[AuthController] ❌ 登出失败", e, stack);
      rethrow;
    }
  }
}
