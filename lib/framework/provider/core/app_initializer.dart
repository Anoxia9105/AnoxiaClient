import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logs/talker.dart';
import '../../services/room_list_service.dart';
import '../auth/auth_controller.dart';

part 'app_initializer.g.dart';

@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  @override
  Future<bool> build() async {
    log.info("🔄 AppInitializer 开始初始化序列...");

    try {
      // 1. 基础服务 (例如: SharedPreferences, Database, Firebase)
      await _initializeServices();

      // 2. 等待 AuthController 完成它的 build() 逻辑
      // 这一步非常关键：它确保了当 AppInitializer 完成时，
      // authControllerProvider 已经完成了 token 校验和用户信息获取
      log.info("🔐 等待认证模块就绪...");
      final user = await ref.read(authControllerProvider.future);

      if (user == null) {
        log.info("👤 用户未登录");
        return false;
      }

      // 3. 业务预加载 (此时已经知道了用户是否登录)
      await _preloadData();

      log.info("✅ 应用全局初始化序列成功完成");
    } catch (e, stack) {
      log.error("❌ 应用初始化崩溃", e, stack);
      // 抛出异常后，state 会变为 AsyncError，Router 会捕获并跳转错误页
      rethrow;
    }

    return true;
  }

  Future<void> _initializeServices() async {
    log.info("🛠️ 正在挂载基础服务...");
    // 这里放真正的异步初始化代码，比如：
    // await LocalStorage.init();
  }

  Future<void> _preloadData() async {
    log.info("📦 正在执行业务预加载...");
    // 可以在这里根据登录状态决定加载什么
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      log.info("👤 用户已登录，开始加载核心业务数据...");

      log.info("💬 正在预加载聊天会话列表...");
      await ref.read(roomListServiceProvider.future);
    }
  }

  /// 手动重置初始化状态 (通常用于注销后的深度清理)
  Future<void> performFullReset() async {
    ref.invalidateSelf();
    await future;
  }
}
