import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/CaptchaModel.dart';
import '../domain/UserInfo.dart';
import '../logs/talker.dart';
import '../network/DioClient.dart';
import '../network/TokenManager.dart';

part 'auth_service.g.dart';

//认证依赖注入
@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

@riverpod
Future<CaptchaModel> captcha(Ref ref) async {
  final repo = ref.read(authServiceProvider);
  return repo.getCaptcha();
}



class AuthService {
  final _client = DioClient();

  Future<CaptchaModel> getCaptcha() async {
    final res = await _client.get("/captchaImage", auth: false);
    return CaptchaModel(uuid: res.data["uuid"], imgBase64: res.data["img"]);
  }

  Future<UserInfo> getUserInfo() async {
    final res = await _client.get("/getInfo");
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
