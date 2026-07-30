import 'dart:async';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:anoxia/framework/codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/protocol/packet_registry.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logs/talker.dart';
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
  static bool _packetParsersRegistered = false;

  @override
  Future<bool> build() async {
    try {
      // 1. 基础服务初始化（如：SharedPreferences、数据库等）
      await _initializeServices();

      // 2. 等待认证模块就绪
      // 确保 AuthController 完成 token 校验和用户信息获取
      final user = await ref.read(authControllerProvider.future);

      if (user == null) {
        log.info('👤 用户未登录');
        return false;
      }

      // 3. 业务数据预加载
      await _preloadData();
    } catch (e, stack) {
      log.error('❌ 应用初始化崩溃', e, stack);
      // 异常会被 Router 捕获并跳转错误页
      rethrow;
    }

    return true;
  }

  /// 初始化基础服务
  Future<void> _initializeServices() async {
    if (_coreServicesInitialized) {
      log.info('🛠️ 基础服务已初始化，跳过重复挂载');
      return;
    }

    if (DeviceUtil.isRealMobile()) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        log.info('🔥 Firebase 初始化完成');
      }

      unawaited(
        PushManager.instance.init().catchError((e, stack) {
          log.error('PushManager 初始化失败', e, stack);
        }),
      );
    }

    _registerPacketParsersOnce();

    _coreServicesInitialized = true;
  }

  void _registerPacketParsersOnce() {
    if (_packetParsersRegistered) {
      return;
    }

    // V5 协议：二进制解析器（payload=Uint8List, codecId=int）
    PacketRegistry.register(
      PacketType.message,
      (payload, codecId) => ImPacketV5.decodeRoomMessage(payload),
    );
    PacketRegistry.registerCodec(
      ImPacketV5.codecRoomMessage,
      PacketType.message,
      (payload, codecId) => ImPacketV5.decodeRoomMessage(payload),
    );
    PacketRegistry.register(
      PacketType.event,
      (payload, codecId) => ImPacketV5.decodeEventMessage(payload),
    );
    PacketRegistry.registerCodec(
      ImPacketV5.codecEventMessage,
      PacketType.event,
      (payload, codecId) => ImPacketV5.decodeEventMessage(payload),
    );
    PacketRegistry.register(
      PacketType.highFrequency,
      (payload, codecId) => ImPacketV5.decodeHighMessage(payload),
    );
    PacketRegistry.registerCodec(
      ImPacketV5.codecHighMessage,
      PacketType.highFrequency,
      (payload, codecId) => ImPacketV5.decodeHighMessage(payload),
    );

    _packetParsersRegistered = true;
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
