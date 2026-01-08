import 'package:notepadclient/framework/provider/auth/auth_state_provider.dart';
import 'package:notepadclient/framework/provider/ws/ws_controller.dart';
import 'package:notepadclient/framework/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/constants/API.dart';
import '../../domain/UserInfo.dart';
import '../../logs/talker.dart';
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
      //没 token，明确未登录
      ref.read(authStateProvider.notifier).logout();
      return;
    }
    try {
      log.info("开始请求用户信息...");

      // await ref.read(authServiceProvider).getUserInfo();
      // 💡 不要直接 await .future，而是读取状态
      final user = await ref
          .read(userInfoProvider.future)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('请求超时');
            },
          );
      // }
    } catch (e) {
      log.error("自动登录失败：$e");
      // await TokenManager.instance.clearToken();
      ref.read(authStateProvider.notifier).setError("自动登录失败");
      // state.setError("自动登录失败");
    }
  }

  Future<void> login(
    String username,
    String password,
    String code,
    String uuid,
  ) async {
    final repo = ref.read(authServiceProvider);
    String token = await repo.login(username, password, code, uuid);
    if (token.isNotEmpty) {
      // 刷新用户信息
      await ref.read(authServiceProvider).getUserInfo();
      ref.read(authStateProvider.notifier).login();
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authServiceProvider);
    await repo.logout();
    ref.read(authStateProvider.notifier).logout();
  }

  /// 登录成功后的统一初始化逻辑
  Future<void> _initializeData() async {
    log.info("开始登录后数据预加载...");

    // 💡 1. 启动 WebSocket (虽然 WsController 监听了 AuthState，但这里可以显式确保)
    // 💡 2. 加载联系人列表 (存入对应的 Provider)
    // 💡 3. 加载房间列表 (获取最新的对话列表)
    // 💡 4. 加载系统配置/表情包等

    await Future.wait([
      // ref.read(contactListProvider.future), // 假设你有一个联系人 Provider
      // ref.read(roomListProvider.future),    // 加载房间列表
    ]);
    ref.read(authStateProvider.notifier).login();
    log.info("所有基础数据加载完成");
  }
}
