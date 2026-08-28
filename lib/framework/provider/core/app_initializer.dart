import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../auth/auth_controller.dart';
import 'login_bootstrap_orchestrator.dart';

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
  static bool _coreServicesInitialized = false;

  @override
  Future<bool> build() async {
    try {
      // 1. 基础服务初始化（如：SharedPreferences、数据库等）
      await _initializeServices();

      // 2. 等待认证模块就绪
      // 确保 AuthController 完成 token 校验和用户信息获取
      final user = await ref.read(authControllerProvider.future);

      if (user == null) {
        return false;
      }

      // 3. 业务数据预加载
      await _preloadData();
    } catch (e, stack) {
      debugLog('❌ 应用初始化崩溃', e, stack);
      // 异常会被 Router 捕获并跳转错误页
      rethrow;
    }

    return true;
  }

  /// 初始化基础服务
  Future<void> _initializeServices() async {
    if (_coreServicesInitialized) {
      return;
    }

    if (DeviceUtil.isRealMobile()) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      unawaited(
        PushManager.instance.init().catchError((e, stack) {
          debugLog('PushManager 初始化失败', e, stack);
        }),
      );
    }

    _coreServicesInitialized = true;
  }

  /// 预加载核心业务数据
  ///
  /// 触发各业务模块的数据加载，确保进入主页面时数据已就绪
  Future<void> _preloadData() async {
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      await ref
          .read(loginBootstrapOrchestratorProvider)
          .run(reason: 'app_initializer');
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
