import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logs/talker.dart';
import '../chat/room/room_list_service.dart';
import '../chat/message/system_event_service.dart';
import '../auth/auth_controller.dart';

part 'app_initializer.g.dart';

/// 应用初始化协调器
///
/// 负责管理应用启动时的初始化序列：
/// 1. 挂载基础服务
/// 2. 等待认证模块就绪
/// 3. 执行业务数据预加载
///
/// 采用 keepAlive 模式，确保初始化结果在全局共享。
@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  @override
  Future<bool> build() async {
    log.info("🔄 AppInitializer 开始初始化序列...");

    try {
      // 1. 基础服务初始化（如：SharedPreferences、数据库等）
      await _initializeServices();

      // 2. 等待认证模块就绪
      // 确保 AuthController 完成 token 校验和用户信息获取
      log.info("🔐 等待认证模块就绪...");
      final user = await ref.read(authControllerProvider.future);

      if (user == null) {
        log.info("👤 用户未登录");
        return false;
      }

      // 3. 业务数据预加载
      await _preloadData();

      log.info("✅ 应用全局初始化序列成功完成");
    } catch (e, stack) {
      log.error("❌ 应用初始化崩溃", e, stack);
      // 异常会被 Router 捕获并跳转错误页
      rethrow;
    }

    return true;
  }

  /// 初始化基础服务
  Future<void> _initializeServices() async {
    log.info("🛠️ 正在挂载基础服务...");
  }

  /// 预加载核心业务数据
  ///
  /// 触发各业务模块的数据加载，确保进入主页面时数据已就绪
  Future<void> _preloadData() async {
    log.info("📦 正在执行业务预加载...");
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      log.info("👤 用户已登录，开始加载核心业务数据...");

      log.info("💬 正在预加载聊天会话列表...");
      await ref.read(roomListServiceProvider.future);

      // 触发消息监听
      ref.read(chatMessagesProvider);

      // 触发系统事件监听
      ref.read(systemEventServiceProvider);

      // 触发后台版本检查（keepAlive，延迟 3s 后自动发起）
      ref.read(appUpdateCheckerProvider);
    }
  }

  /// 执行完整重置
  ///
  /// 通常用于注销后的深度清理，重新执行整个初始化流程
  Future<void> performFullReset() async {
    ref.invalidateSelf();
    await future;
  }
}
