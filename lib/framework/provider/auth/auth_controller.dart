import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/ss_util.dart';
import 'package:anoxia/framework/provider/core/auth_repository_provider.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:anoxia/framework/core/device_identity.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:anoxia/platform/shims/cross_tab_session_sync_shim.dart';
import '../../domain/captcha_model.dart';
import '../../domain/user_info.dart';
import '../../local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../../network/token_manager.dart';
import '../chat/room/room_list_service.dart';
import '../contact/contact_list_controller.dart';
import '../core/app_initializer.dart';
import '../core/session_reset_service.dart';
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
    debugLog('🔧 AuthController 初始化完成，尝试自动恢复登录...');

    final token = await TokenManager.instance.getToken();
    debugLog("[AuthController] 自动恢复: token ${token != null ? '存在' : '不存在'}");
    if (token == null || token.isEmpty) return null;

    try {
      // 恢复 token 到内存缓存
      ref.read(tokenCacheProvider.notifier).setToken(token);
      final user = await _fetchUserInfo();
      if (user != null) {
        // 自动恢复成功路径也要校验本地缓存归属：上次登录的是其他账号时，
        // 先清空会话缓存，避免把上一个账号的会话/消息/头像残留带进来。
        await _ensureSessionCacheMatches(user.userId);
        _registerPushTokenRefreshBinding(user);
        unawaited(_bindPushDevice(user));
      }
      return user;
    } catch (e, st) {
      debugLog('[AuthController] 自动恢复失败', e, st);
      await TokenManager.instance.clearToken();
      ref.read(tokenCacheProvider.notifier).clearToken();
      await _clearLocalSessionCache();
      return null;
    }
  }

  /// 用户登录
  ///
  /// [account] 用户名或邮箱
  /// [password] 密码
  /// [code] 图形验证码
  /// [uuid] 验证码 UUID
  ///
  /// 登录成功后自动恢复会话，并触发 [AppInitializer] 重置。
  Future<void> login(
    String account,
    String password,
    String code,
    String uuid,
  ) async {
    state = const AsyncLoading();

    try {
      final token = await ref.read(authRepositoryProvider).login(
            account: account,
            password: password,
            code: code,
            uuid: uuid,
            deviceId:
                await DeviceIdentity.instance.getPlatformQualifiedId(),
          );
      if (token == null || token.isEmpty) {
        throw Exception('login_failed'.tr());
      }

      // 同时保存到 TokenManager 和内存缓存
      await TokenManager.instance.setToken(token);
      ref.read(tokenCacheProvider.notifier).setToken(token);
      await _clearLocalSessionCache();

      final user = await _fetchUserInfo();
      if (user != null) {
        await SSUtil.instance.write(
          key: StorageKeys.lastLoginUserId,
          value: '${user.userId}',
        );
      }
      state = AsyncData(user);
    } catch (e, st) {
      debugLog('[AuthController] 登录失败', e, st);
      state = AsyncError(e, st);
      // 统一展示后端返回的错误信息（验证码错误/失效、密码错误等）
      ref.read(toastServiceProvider).showToast(
            _parseLoginErrorMessage(e),
            type: ToastType.error,
          );
      rethrow;
    }

    // 登录成功后重新触发 App 初始化（_preloadData 在登出时不会为新 session 重跑）
    if (state is AsyncData && state.value != null) {
      _registerPushTokenRefreshBinding(state.value!);
      unawaited(_bindPushDevice(state.value!));
      // 清掉未登录阶段可能遗留的空房间列表缓存，避免登录后先闪空态。
      ref.invalidate(roomListServiceProvider);
      debugLog('[AuthController] 登录成功，重新触发 App 初始化序列...');
      ref.invalidate(appInitializerProvider);

      // 通知其它标签页已切换账号，避免共享缓存被新账号数据覆盖后仍显示
      // 旧账号的头像/昵称（Web 端生效，原生端为空实现）。
      CrossTabSessionSync.instance.broadcastLogin(state.value?.userId);
    }
  }

  Future<String> sendRegisterEmailCode({
    required String email,
    required String captchaCode,
    required String uuid,
  }) {
    return ref.read(authRepositoryProvider).sendRegisterEmailCode(
          email: email,
          captchaCode: captchaCode,
          uuid: uuid,
        );
  }

  Future<String> verifyRegisterEmailCode({
    required String email,
    required String emailCode,
  }) {
    return ref.read(authRepositoryProvider).verifyRegisterEmailCode(
          email: email,
          emailCode: emailCode,
        );
  }

  Future<String> register({
    required String username,
    required String email,
    required String emailVerificationToken,
    required String password,
  }) {
    return ref.read(authRepositoryProvider).register(
          username: username,
          email: email,
          emailVerificationToken: emailVerificationToken,
          password: password,
        );
  }

  /// 忘记密码：发送邮箱验证码
  Future<String> forgotPasswordSendCode({
    required String username,
    required String captchaCode,
    required String uuid,
  }) {
    return ref.read(authRepositoryProvider).forgotPasswordSendCode(
          username: username,
          captchaCode: captchaCode,
          uuid: uuid,
        );
  }

  /// 忘记密码：重置密码
  Future<String> forgotPasswordReset({
    required String username,
    required String emailCode,
    required String newPassword,
    required String confirmPassword,
  }) {
    return ref.read(authRepositoryProvider).forgotPasswordReset(
          username: username,
          emailCode: emailCode,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );
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

  Future<void> logout({
    SessionResetReason reason = SessionResetReason.logout,
    bool notifyBackend = true,
  }) async {
    // 防止递归调用（如 logout 接口本身返回 401 又触发 logout）
    if (_isLoggingOut) return;
    // 已处于登出态时直接返回，不再重复重置会话缓存。
    // 否则 DioClient 的 401 处理器会在 keepAlive 的 roomListService 等
    // Provider 被本流程 invalidate 后重建出新的加签请求，请求再次 401，
    // 再次触发本方法，形成无限 401→登出→重建→再 401 循环（Windows 端
    // 冷启动未登录时尤其明显，登出后回登录页也会被循环请求打断）。
    if (state is AsyncData && state.value == null) return;
    _isLoggingOut = true;

    final token = ref.read(tokenCacheProvider);
    final previousUser = state.value;

    PushManager.instance.setOnFcmTokenChanged(null);
    unawaited(_unbindPushDevice(token));

    // 手动登出时异步通知后端；鉴权失效触发的本地登出不再重复请求。
    if (notifyBackend) {
      unawaited(ref.read(authRepositoryProvider).logout(token: token));
    }

    try {
      // 1. 清除本地存储的 Token
      await TokenManager.instance.clearToken();

      // 2. 清除内存中的 Token
      ref.read(tokenCacheProvider.notifier).clearToken();

      // 3. 切换认证态，触发路由回到登录页。
      //    WsController 自身已通过 ref.listen(authControllerProvider) 监听此变化，
      //    会在这里自动断开连接并禁用重连，无需在此手动操作，避免循环依赖。
      await _clearLocalSessionCache();
      state = const AsyncData(null);

      // 通知其它标签页本账号已登出（Web 端生效，原生端为空实现）。
      CrossTabSessionSync.instance.broadcastLogout(previousUser?.userId);

      // 4. 统一清理会话级缓存，避免切账号后复用旧会话数据
      SessionResetService.instance.reset(ref, reason: reason);

      debugLog('[AuthController] 登出成功，全部业务缓存已清理');
    } catch (e, st) {
      debugLog('[AuthController] 登出清理异常', e, st);
      // 即使出错也强制设为 null，确保用户能回到登录页
      state = const AsyncData(null);
    } finally {
      _isLoggingOut = false;
    }
  }

  /// 获取用户信息
  Future<UserInfo?> _fetchUserInfo() {
    return ref.read(authRepositoryProvider).fetchUserInfo();
  }

  Future<void> _clearLocalSessionCache() async {
    await ref.read(localDataSourceProvider).clearSessionCache();
    ref.invalidate(contactListServiceProvider);
    ref.invalidate(sortedContactGroupsProvider);
  }

  /// 校验本地会话缓存是否属于当前用户
  ///
  /// 上次登录成功的用户与当前用户不一致时，先清空本地缓存（含会话、
  /// 消息、联系人、同步水位），再记录当前用户 ID，避免切账号后复用旧数据。
  Future<void> _ensureSessionCacheMatches(int userId) async {
    final lastUserIdRaw = await SSUtil.instance.read(
      key: StorageKeys.lastLoginUserId,
    );
    final lastUserId = int.tryParse(lastUserIdRaw ?? '');
    if (lastUserId != null && lastUserId != userId) {
      debugLog(
        '[AuthController] 检测到上次登录用户($lastUserId)与当前用户($userId)'
        '不一致，清理本地会话缓存',
      );
      await _clearLocalSessionCache();
    }
    await SSUtil.instance.write(
      key: StorageKeys.lastLoginUserId,
      value: '$userId',
    );
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

  Future<void> _bindPushDevice(UserInfo user) async {
    if (!_shouldReportPushDevice()) return;

    try {
      final payload = await PushManager.instance.buildDeviceBindPayload(
        userId: user.userId,
      );
      await ref.read(authRepositoryProvider).bindPushDevice(payload);
      debugLog('[AuthController] 推送设备绑定上报成功');
    } catch (e, st) {
      debugLog('[AuthController] 推送设备绑定上报失败: $e');
      debugLog('[AuthController] 推送设备绑定上报异常', e, st);
    }
  }

  void _registerPushTokenRefreshBinding(UserInfo user) {
    if (!_shouldReportPushDevice()) return;

    PushManager.instance.setOnFcmTokenChanged((token) async {
      debugLog('[AuthController] 检测到 FCM token 变更，触发设备绑定刷新');
      await _bindPushDevice(user);
    });
  }

  Future<void> _unbindPushDevice(String? token) async {
    if (!_shouldReportPushDevice()) return;

    try {
      final deviceUid = await PushManager.instance.getOrCreateDeviceUid();
      await ref.read(authRepositoryProvider).unbindPushDevice(
            deviceUid,
            token: token,
          );
      debugLog('[AuthController] 推送设备解绑上报成功');
    } catch (e) {
      debugLog('[AuthController] 推送设备解绑上报失败（忽略）: $e');
    }
  }

  bool _shouldReportPushDevice() => DeviceUtil.isRealMobile();

  /// 解析登录错误信息，优先展示后端返回的具体错误文案
  ///
  /// 验证码错误/过期、用户名或密码错误等场景，后端统一返回
  /// `{code: 非200, msg: 具体原因}`；Dio 异常时从响应体中提取 msg。
  /// 无法获取后端文案时回退到通用提示。
  String _parseLoginErrorMessage(Object error) {
    String? message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['msg'] ?? data['message'];
        if (msg is String && msg.trim().isNotEmpty) {
          message = msg.trim();
        }
      }
    } else {
      final raw = error.toString();
      message = raw.startsWith('Exception:')
          ? raw.substring('Exception:'.length).trim()
          : raw.trim();
    }
    if (message == null || message.isEmpty) {
      return 'login_failed'.tr();
    }
    return message;
  }
}

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片
@riverpod
Future<CaptchaModel> getCaptcha(Ref ref) async {
  return ref.read(authRepositoryProvider).fetchCaptcha();
}
