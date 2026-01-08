import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/CaptchaModel.dart';
import '../domain/UserInfo.dart';
import '../network/DioClient.dart';
import '../network/TokenManager.dart';

part 'auth_service.g.dart';

//认证依赖注入
@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

//获取验证码
@riverpod
Future<CaptchaModel> captcha(Ref ref) async {
  final repo = ref.watch(authServiceProvider);
  return repo.getCaptcha();
}

// 获取用户信息 (核心：保持活跃，并处理异常)
@Riverpod(keepAlive: true)
Future<UserInfo> userInfo(Ref ref) async {
  final repo = ref.watch(authServiceProvider);
  try {
    return await repo.getUserInfo();
  } catch (e) {
    rethrow; // 抛出错误让 AuthState 监听到
  }
}

class AuthService {
  final _client = DioClient();

  Future<CaptchaModel> getCaptcha() async {
    final res = await _client.get("/captchaImage", auth: false);
    return CaptchaModel(uuid: res.data["uuid"], imgBase64: res.data["img"]);
  }

  Future<UserInfo> getUserInfo() async {
    final res = await DioClient().get("/getInfo");
    return UserInfo.fromJson(res.data["data"]);
  }

  Future<String> login(
    String username,
    String password,
    String code,
    String uuid,
  ) async {
    final res = await _client.post(
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
    return token;
  }

  Future<void> logout() async {
    await TokenManager.instance.clearToken();
  }
}
