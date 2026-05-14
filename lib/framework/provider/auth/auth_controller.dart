import 'dart:async';
import 'dart:io' as io;

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import '../../domain/CaptchaModel.dart';
import '../../domain/UserInfo.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../core/app_initializer.dart';
import 'token_provider.dart';

part 'auth_controller.g.dart';

/// 认证状态管理器
///
/// 负责用户登录、登出和会话恢复的核心 Provider。
/// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<UserInfo?> build() async {
    log.info("🔧 AuthController 初始化完成，尝试自动恢复登录...");

    final token = await TokenManager.instance.getToken();
    log.info("[AuthController] 自动恢复: token ${token != null ? '存在' : '不存在'}");
    if (token == null || token.isEmpty) return null;

    try {
      // 恢复 token 到内存缓存
      ref.read(tokenCacheProvider.notifier).setToken(token);
      return await _fetchUserInfo();
    } catch (e, st) {
      log.error("[AuthController] 自动恢复失败", e, st);
      await TokenManager.instance.clearToken();
      ref.read(tokenCacheProvider.notifier).clearToken();
      return null;
    }
  }

  /// 用户登录
  ///
  /// [username] 用户名
  /// [password] 密码
  /// [code] 图形验证码
  /// [uuid] 验证码 UUID
  ///
  /// 登录成功后自动恢复会话，并触发 [AppInitializer] 重置。
  Future<void> login(
    String username,
    String password,
    String code,
    String uuid,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final res = await DioClient().post(
        API.login,
        data: {
          "username": username,
          "password": password,
          "code": code,
          "uuid": uuid,
          "deviceId": _buildDeviceId(),
        },
        auth: false,
      );
      if (res.data["token"] == null) {
        Toast.showToast("login_failed".tr(), type: ToastType.error);
        return null;
      }
      String token = res.data["token"];

      // 同时保存到 TokenManager 和内存缓存
      await TokenManager.instance.setToken(token);
      ref.read(tokenCacheProvider.notifier).setToken(token);

      return await _fetchUserInfo();
    });

    // 登录成功后重新触发 App 初始化（_preloadData 在登出时不会为新 session 重跑）
    if (state is AsyncData && state.value != null) {
      log.info("[AuthController] 登录成功，重新触发 App 初始化序列...");
      ref.invalidate(appInitializerProvider);
    }
  }

  /// 用户登出
  ///
  /// 执行以下清理操作：
  /// 1. 调用后端 logout API（异步，不阻塞）
  /// 2. 清除本地存储的 Token
  /// 3. 清除内存中的 Token
  /// 4. 重置 [appInitializerProvider]（强制销毁并重建）
  ///
  /// 注意：无需手动断开 WebSocket，[WsController] 通过监听认证状态自动处理
  bool _isLoggingOut = false;

  Future<void> logout() async {
    // 防止递归调用（如 logout 接口本身返回 401 又触发 logout）
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    final token = ref.read(tokenCacheProvider);

    // 后端登出改为异步通知，不阻塞本地退出速度
    unawaited((() async {
      try {
        await DioClient()
            .post(
              API.logout,
              auth: false,
              options: Options(
                headers: {
                  if (token != null && token.isNotEmpty)
                    'Authorization': 'Bearer $token',
                },
              ),
            )
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        log.warning("[AuthController] 后端登出请求失败（忽略）: $e");
      }
    })());

    try {
      // 1. 清除本地存储的 Token
      await TokenManager.instance.clearToken();

      // 2. 清除内存中的 Token
      ref.read(tokenCacheProvider.notifier).clearToken();

      // 3. 切换认证态，触发路由回到登录页。
      //    WsController 自身已通过 ref.listen(authControllerProvider) 监听此变化，
      //    会在这里自动断开连接并禁用重连，无需在此手动操作，避免循环依赖。
      state = const AsyncData(null);

      log.info("[AuthController] 登出成功，全部业务缓存已清理");
    } catch (e, st) {
      log.error("[AuthController] 登出清理异常", e, st);
      // 即使出错也强制设为 null，确保用户能回到登录页
      state = const AsyncData(null);
    } finally {
      _isLoggingOut = false;
    }
  }

  /// 获取用户信息
  Future<UserInfo?> _fetchUserInfo() async {
    final res = await DioClient().get(API.getInfo);
    return UserInfo.fromJson(res.data["data"]);
  }

  /// 刷新当前登录用户信息
  ///
  /// 用于用户资料更新后同步 UI 展示
  Future<void> refreshUserInfo() async {
    final current = state.value;
    if (current == null) return;

    final next = await _fetchUserInfo();
    state = AsyncData(next);
  }

  /// 登出操作（Mutation 预留）
  static final logoutMutation = Mutation<void>();

  /// 登录操作（Mutation 预留）
  static final loginMutation = Mutation<void>();

  /// 构建设备标识
  ///
  /// 用于后端识别客户端类型和平台
  String _buildDeviceId() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return io.Platform.operatingSystem;
    }
  }
}

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片
@riverpod
Future<CaptchaModel> getCaptcha(Ref ref) async {
  final res = await DioClient().get(API.captchaImage, auth: false);
  return CaptchaModel(uuid: res.data["uuid"], imgBase64: res.data["img"]);
}
