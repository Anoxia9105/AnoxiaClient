import 'dart:async';
import 'dart:io';

import 'package:notepadclient/Flavor.dart';
import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/network/DioClient.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/core/utils/StringUtil.dart';
import 'package:notepadclient/features/auth/service/IAuthService.dart';
import 'package:notepadclient/shared/widgets/Toast.dart';

import '../../../../core/constants/StorageKeys.dart';

class AuthServiceImpl extends ApiBase implements IAuthService {
  final DioClient client = DioClient();
  Timer? _refreshTimer;

  @override
  Future<Captcha> getCaptchaImage() async {
    final response = await client.get(pathCaptchaImage(), auth: false);
    return Captcha.fromJson(response.data);
  }

  @override
  Future<SysUser?> loginByToken(Map<String, String> loginData) async {
    final response = await client.post(
      pathLogin(),
      data: loginData,
      auth: false,
    );
    String token = response.data["token"] ?? '';

    if (StringUtil.isNotEmpty(token)) {
      //重新登录设置新的 Token 用于获取用户信息 后续覆盖过期时间
      SSUtil.instance.write(key: StorageKeys.accessToken, value: token);

      connect(token);

      SysUser? user = await getUserInfo();
      if (user == null) return null;
      final timeoutMinutes =
          int.tryParse(user.data?.params?.timeout ?? '30') ?? 30;

      await SPUtil.instance.set<SysUser>(StorageKeys.sysUser, user);
      SSUtil.instance.write(
        key: StorageKeys.accessToken,
        value: token,
        expiry: Duration(minutes: timeoutMinutes),
      );

      await refreshToken(timeoutMinutes);
      return user;
    }
    return null;
  }

  @override
  Future<void> refreshToken(int minutes) async {
    final refreshInterval = Duration(minutes: minutes > 1 ? minutes - 1 : 1);
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      final response = await client.get(pathRefreshToken());
      if (response.statusCode != HttpStatus.ok) {
        Toast.showToast("令牌即将过期，稍后请重新登录", type: ToastType.warning);
      }
    });
  }

  @override
  Future<void> logout() async {
    _refreshTimer?.cancel(); // 停掉续期任务
    _refreshTimer = null;

    final response = await client.get(pathLogout());
    if (response.statusCode != HttpStatus.ok) {
      Toast.showToast("退出登录失败了！", type: ToastType.error);
    }
  }

  @override
  Future<SysUser?> getUserInfo() async {
    final response = await client.get(pathGetInfo());
    if (response.statusCode != HttpStatus.ok || response.data == null) {
      return null;
    }

    if (response.data["code"] != HttpStatus.ok) {
      return null;
    }

    SysUser user = SysUser.fromJson(response.data);
    return user;
  }

  @override
  Future<void> connect(String token) async {
    getIt.registerSingleton<IMClient>(
      IMClient(
        url: "${FlavorConfig.value.wsBaseUrl}${pathSocket(token)}",
        heartbeatInterval: const Duration(seconds: 30),
        // 可自定义 encoder/decoder，如果服务器是 JSON，默认实现已足够
        // decoder: (raw) => jsonDecode(raw),
        // encoder: (msg) => jsonEncode(msg),
        pingMessage: {'type': 'ping'},
        pongMatcher: (dynamic message) {
          // 自定义 pong 判定逻辑：返回 true 则视为 pong
          if (message == 'pong') return true;
          return false;
        },
      ),
    );
  }
}
