import 'package:notepadclient/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import '../../domain/CaptchaModel.dart';
import '../../domain/UserInfo.dart';
import '../../logs/talker.dart';
import '../../network/TokenManager.dart';
import '../core/app_initializer.dart';

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
      return await _fetchUserInfo();
    } catch (e, st) {
      log.error("[AuthController] 自动恢复失败", e, st);
      await TokenManager.instance.clearToken();
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
        "/login",
        data: {
          "username": username,
          "password": password,
          "code": code,
          "uuid": uuid,
        },
        auth: false,
      );
      String token = res.data["token"];
      await TokenManager.instance.setToken(token);
      return await _fetchUserInfo();
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await TokenManager.instance.clearToken();
    state = const AsyncData(null);
  }

  // 内部辅助方法
  Future<UserInfo?> _fetchUserInfo() async {
    final res = await DioClient().get("/getInfo");
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
  final res = await DioClient().get("/captchaImage", auth: false);
  return CaptchaModel(uuid: res.data["uuid"], imgBase64: res.data["img"]);
}
