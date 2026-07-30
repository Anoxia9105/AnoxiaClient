import 'dart:async';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:anoxia/framework/core/device_identity.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import '../../domain/captcha_model.dart';
import '../../domain/user_info.dart';
import '../../local_cache/cache_providers.dart';
import '../../logs/talker.dart';
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
    log.info('🔧 AuthController 初始化完成，尝试自动恢复登录...');

    final token = await TokenManager.instance.getToken();
    log.info("[AuthController] 自动恢复: token ${token != null ? '存在' : '不存在'}");
    if (token == null || token.isEmpty) return null;

    try {
      // 恢复 token 到内存缓存
      ref.read(tokenCacheProvider.notifier).setToken(token);
      final user = await _fetchUserInfo();
      if (user != null) {
        _registerPushTokenRefreshBinding(user);
        unawaited(_bindPushDevice(user));
      }
      return user;
    } catch (e, st) {
      log.error('[AuthController] 自动恢复失败', e, st);
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

    state = await AsyncValue.guard(() async {
      final res = await DioClient().post(
        API.login,
        data: {
          'username': account,
          'password': password,
          'code': code,
          'uuid': uuid,
          'deviceId': await DeviceIdentity.instance.getPlatformQualifiedId(),
        },
        auth: false,
      );
      if (res.data['token'] == null) {
        Toast.showToast('login_failed'.tr(), type: ToastType.error);
        return null;
      }
      String token = res.data['token'];

      // 同时保存到 TokenManager 和内存缓存
      await TokenManager.instance.setToken(token);
      ref.read(tokenCacheProvider.notifier).setToken(token);
      await _clearLocalSessionCache();

      return await _fetchUserInfo();
    });

    // 登录成功后重新触发 App 初始化（_preloadData 在登出时不会为新 session 重跑）
    if (state is AsyncData && state.value != null) {
      _registerPushTokenRefreshBinding(state.value!);
      unawaited(_bindPushDevice(state.value!));
      // 清掉未登录阶段可能遗留的空房间列表缓存，避免登录后先闪空态。
      ref.invalidate(roomListServiceProvider);
      log.info('[AuthController] 登录成功，重新触发 App 初始化序列...');
      ref.invalidate(appInitializerProvider);
    }
  }

  Future<String> sendRegisterEmailCode({
    required String email,
    required String captchaCode,
    required String uuid,
  }) async {
    final res = await DioClient().post(
      API.registerSendEmailCode,
      data: {'email': email, 'code': captchaCode, 'uuid': uuid},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    return msg;
  }

  Future<String> verifyRegisterEmailCode({
    required String email,
    required String emailCode,
  }) async {
    final res = await DioClient().post(
      API.registerVerifyEmailCode,
      data: {'email': email, 'emailCode': emailCode},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '邮箱验证失败');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    final token = res.data is Map ? res.data['data']?.toString() : null;
    if (token == null || token.isEmpty) throw Exception('邮箱验证凭证无效');
    return token;
  }

  Future<String> register({
    required String username,
    required String email,
    required String emailVerificationToken,
    required String password,
  }) async {
    final res = await DioClient().post(
      API.register,
      data: {
        'username': username,
        'email': email,
        'emailVerificationToken': emailVerificationToken,
        'password': password,
      },
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '注册成功');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    return msg;
  }

  /// 忘记密码：发送邮箱验证码
  Future<String> forgotPasswordSendCode({
    required String username,
    required String captchaCode,
    required String uuid,
  }) async {
    final res = await DioClient().post(
      API.forgotPasswordSendCode,
      data: {'username': username, 'captchaCode': captchaCode, 'uuid': uuid},
      auth: false,
    );

    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) {
      throw Exception(msg);
    }
    return msg;
  }

  /// 忘记密码：重置密码
  Future<String> forgotPasswordReset({
    required String username,
    required String emailCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await DioClient().post(
      API.forgotPasswordReset,
      data: {
        'username': username,
        'emailCode': emailCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      auth: false,
    );

    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) {
      throw Exception(msg);
    }
    return msg;
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
    _isLoggingOut = true;

    final token = ref.read(tokenCacheProvider);

    PushManager.instance.setOnFcmTokenChanged(null);
    unawaited(_unbindPushDevice(token));

    // 手动登出时异步通知后端；鉴权失效触发的本地登出不再重复请求。
    if (notifyBackend) {
      unawaited(
        (() async {
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
            log.warning('[AuthController] 后端登出请求失败（忽略）: $e');
          }
        })(),
      );
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

      // 4. 统一清理会话级缓存，避免切账号后复用旧会话数据
      SessionResetService.instance.reset(ref, reason: reason);

      log.info('[AuthController] 登出成功，全部业务缓存已清理');
    } catch (e, st) {
      log.error('[AuthController] 登出清理异常', e, st);
      // 即使出错也强制设为 null，确保用户能回到登录页
      state = const AsyncData(null);
    } finally {
      _isLoggingOut = false;
    }
  }

  /// 获取用户信息
  Future<UserInfo?> _fetchUserInfo() async {
    final res = await DioClient().get(API.getInfo);
    return UserInfo.fromJson(res.data['data']);
  }

  Future<void> _clearLocalSessionCache() async {
    await ref.read(localDataSourceProvider).clearSessionCache();
    ref.invalidate(contactListServiceProvider);
    ref.invalidate(sortedContactGroupsProvider);
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
      await DioClient().post(API.pushDeviceBind, data: payload);
      log.info('[AuthController] 推送设备绑定上报成功');
    } catch (e, st) {
      log.warning('[AuthController] 推送设备绑定上报失败: $e');
      log.error('[AuthController] 推送设备绑定上报异常', e, st);
    }
  }

  void _registerPushTokenRefreshBinding(UserInfo user) {
    if (!_shouldReportPushDevice()) return;

    PushManager.instance.setOnFcmTokenChanged((token) async {
      log.info('[AuthController] 检测到 FCM token 变更，触发设备绑定刷新');
      await _bindPushDevice(user);
    });
  }

  Future<void> _unbindPushDevice(String? token) async {
    if (!_shouldReportPushDevice()) return;

    try {
      final deviceUid = await PushManager.instance.getOrCreateDeviceUid();
      await DioClient().delete(
        '${API.pushDeviceUnbind}?deviceUid=${Uri.encodeQueryComponent(deviceUid)}',
        auth: false,
        options: Options(
          extra: {'skipAuthFailureLogout': true},
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      log.info('[AuthController] 推送设备解绑上报成功');
    } catch (e) {
      log.warning('[AuthController] 推送设备解绑上报失败（忽略）: $e');
    }
  }

  bool _shouldReportPushDevice() => DeviceUtil.isRealMobile();

  bool _isApiSuccess(dynamic body) {
    if (body is! Map) return true;

    final code = body['code'];
    if (code is num) return code == 200;
    if (code is String) return code == '200' || code == '0';

    final nestedData = body['data'];
    if (nestedData is Map) {
      final nestedCode = nestedData['code'];
      if (nestedCode is num) return nestedCode == 200;
      if (nestedCode is String) return nestedCode == '200' || nestedCode == '0';
    }

    return true;
  }

  String _extractApiMsg(dynamic body, {required String fallback}) {
    if (body is! Map) return fallback;

    final msg = body['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();

    final nestedData = body['data'];
    if (nestedData is Map) {
      final nestedMsg = nestedData['msg'];
      if (nestedMsg is String && nestedMsg.trim().isNotEmpty) {
        return nestedMsg.trim();
      }
    }

    return fallback;
  }
}

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片
@riverpod
Future<CaptchaModel> getCaptcha(Ref ref) async {
  final res = await DioClient().get(API.captchaImage, auth: false);
  return CaptchaModel(uuid: res.data['uuid'], imgBase64: res.data['img']);
}
