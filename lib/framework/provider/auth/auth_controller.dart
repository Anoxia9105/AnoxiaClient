import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import '../../domain/CaptchaModel.dart';
import '../../domain/UserInfo.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../chat/room/room_list_service.dart';
import 'token_provider.dart';

part 'auth_controller.g.dart';

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

  /// 手动登录：调用后会把 state 设为 AsyncData(user)
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
        },
        auth: false,
      );
      if (res.data["token"] == null) {
        Toast.showToast("登录失败,请检查用户名/密码/验证码是否正确", type: ToastType.error);
        return null;
      }
      String token = res.data["token"];
      
      // 同时保存到 TokenManager 和内存缓存
      await TokenManager.instance.setToken(token);
      ref.read(tokenCacheProvider.notifier).setToken(token);
      
      return await _fetchUserInfo();
    });
  }

  /// 手动登出：调用后会把 state 设为 AsyncData(null)
  /// 1. 调用后端 logout API
  /// 2. 清除本地存储的 Token
  /// 3. 清除内存中的 Token
  /// 4. 【关键步骤】：重置所有业务 Provider
  ///    - invalidate 会强制销毁当前 Provider 实例，下次使用时重新执行 build()
  ///    - 这里重置了 roomListServiceProvider 和 activeRoomIdProvider
  Future<void> logout() async {
    try {
      // . 调用后端 logout API
      await DioClient().post(API.logout);

      // . 清除本地存储的 Token
      await TokenManager.instance.clearToken();
      
      // . 清除内存中的 Token
      ref.read(tokenCacheProvider.notifier).clearToken();

      // . 【关键步骤】：重置所有业务 Provider
      // invalidate 会强制销毁当前 Provider 实例，下次使用时重新执行 build()
      ref.invalidate(roomListServiceProvider);
      ref.invalidate(activeRoomIdProvider);

      state = const AsyncData(null);
      log.info("[AuthController] 登出成功，业务缓存已清理");
    } catch (e, st) {
      log.error("[AuthController] 登出异常", e, st);
      // 即使出错，通常也强制设为 null 确保用户能回到登录页
      state = const AsyncData(null);
    }
  }

  // 内部辅助方法
  Future<UserInfo?> _fetchUserInfo() async {
    final res = await DioClient().get(API.getInfo);
    return UserInfo.fromJson(res.data["data"]);
  }

  /// logout mutation action
  static final logoutMutation = Mutation<void>();

  /// logout mutation action
  static final loginMutation = Mutation<void>();
}

@riverpod
/// 获取验证码
Future<CaptchaModel> getCaptcha(Ref ref) async {
  final res = await DioClient().get(API.captchaImage, auth: false);
  return CaptchaModel(uuid: res.data["uuid"], imgBase64: res.data["img"]);
}
