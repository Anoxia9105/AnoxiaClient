import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logs/talker.dart';
import '../auth/auth_controller.dart';

part 'app_initializer.g.dart';

@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  /// 标记初始化是否已完成
  bool _initialized = false;

  @override
  FutureOr<void> build() {
    log.info("🔄 AppInitializer.build() 被调用，_initialized: $_initialized");
    // 如果已经初始化过，直接返回
    if (_initialized) {
      log.info("✅ 应用已初始化，跳过重复初始化");
      return null;
    }
    log.info("⏳ 开始异步初始化...");
    // 执行异步初始化
    return _initialize();
  }

  /// 初始化应用
  Future<void> _initialize() async {
    try {
      log.info("🚀 应用开始初始化...");
      await Future.delayed(const Duration(seconds: 5));
      // 1. 基础服务初始化
      await _initializeServices();

      // 2. 自动登录检查
      await _checkAutoLogin();

      // 3. 预加载数据（可选）
      await _preloadData();

      _initialized = true;
      log.info("✅ 应用初始化完成");
    } catch (e, stack) {
      log.error("❌ 应用初始化失败", e, stack);
      rethrow;
    }
  }

  /// 初始化基础服务
  Future<void> _initializeServices() async {
    log.info("🛠️ 初始化基础服务...");

    // 这里可以初始化各种服务，如：
    // - 数据库
    // - 本地存储
    // - 通知服务
    // - 其他第三方服务

    await Future.delayed(const Duration(milliseconds: 100)); // 模拟初始化时间
    log.info("✅ 基础服务初始化完成");
  }

  /// 检查自动登录
  Future<void> _checkAutoLogin() async {
    log.info("🔐 检查自动登录...");

    // 注意：这里使用 notifier 调用 autoLogin 方法
    // 而不是直接读取，因为我们需要执行异步操作 内部处理异常
    await ref.read(authControllerProvider.notifier).autoLogin();
    log.info("✅ 自动登录检查完成");
  }

  /// 预加载数据
  Future<void> _preloadData() async {
    log.info("📦 预加载数据...");

    // 这里可以预加载一些数据，如：
    // - 配置信息
    // - 用户偏好设置
    // - 缓存的资源

    await Future.delayed(const Duration(milliseconds: 50)); // 模拟加载时间
    log.info("✅ 数据预加载完成");
  }

  /// 手动重新初始化（用于特殊场景，如清除缓存后）
  Future<void> reinitialize() async {
    _initialized = false;
    state = const AsyncValue.data(null);
    await future; // 等待重新初始化完成
  }
}
