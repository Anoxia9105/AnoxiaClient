import 'dart:async';
import 'dart:io';

import 'package:notepadclient/Flavor.dart';
import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/network/DioClient.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/core/network/TokenManager.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/core/utils/StringUtil.dart';
import 'package:notepadclient/features/auth/service/IAuthService.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/shared/widgets/Toast.dart';

import '../../../../core/constants/StorageKeys.dart';

class AuthServiceImpl extends ApiBase implements IAuthService {
  Timer? _refreshTimer;

  @override
  Future<Captcha> getCaptchaImage() async {
    final response = await get(pathCaptchaImage(), auth: false);
    return Captcha.fromJson(response.data);
  }

  @override
  Future<SysUser?> login({Map<String, String>? loginData, autoLogin = false}) async {
    final String? token;

    //是自动登录
    if(autoLogin){
      token = await TokenManager.instance.getToken();
    }else{
      token = await _loginByToken(loginData!);
    }

    if (StringUtil.isNullOrEmpty(token)) return null;

    //重新登录设置新的 Token 用于获取用户信息 后续覆盖过期时间
    await TokenManager.instance.setToken(token!);

    SysUser? user = await _getUserInfo();
    if (user == null) return null;
    final timeoutMinutes =
        int.tryParse(user.data?.params?.timeout ?? '30') ?? 30;
    //存储密钥
    final secret = user.data?.params?.secret ?? '';
    SSUtil.instance.write(key: StorageKeys.secret, value: secret);

    //清空密钥 不明文保留缓存中
    user = user.copyWith(
      data: user.data?.copyWith(
        params: user.data?.params?.copyWith(secret: ''),
      ),
    );

    //写入本地缓存
    await SPUtil.instance.set<SysUser>(StorageKeys.sysUser, user);
    // 通过 TokenManager 写入（含过期）
    await TokenManager.instance.setToken(token, expiry: Duration(minutes: timeoutMinutes));
    //刷新token
    await _refreshToken(timeoutMinutes);
    //连接服务器
    await _connect(token);
    return user;
  }

  @override
  Future<void> logout() async {
    _refreshTimer?.cancel(); // 停掉续期任务
    _refreshTimer = null;

    final response = await get(pathLogout());
    if (response.statusCode != HttpStatus.ok) {
      Toast.showToast("退出登录失败了！", type: ToastType.error);
    }
  }

  Future<SysUser?> _getUserInfo() async {
    final response = await get(pathGetInfo());
    if (response.statusCode != HttpStatus.ok || response.data == null) {
      return null;
    }
    print("======================");
    print(response.data);

    if (response.data["code"] != HttpStatus.ok) {
      return null;
    }

    SysUser user = SysUser.fromJson(response.data);
    return user;
  }

  Future<String?> _loginByToken(Map<String, String> loginData) async {
    final response = await post(
      pathLogin(),
      data: loginData,
      auth: false,
    );
    return response.data["token"];
  }

  Future<void> _connect(String token) async {
    final imClient = IMClient(
      url: "${FlavorConfig.value.wsBaseUrl}${pathSocket(token)}",
      logger: (String tag, String message) {
        print("$tag --> $message");
      },
    );
    //注册到 DI
    getIt.registerSingleton<IMClient>(imClient);
    //绑定到 ChatController
    getIt<ChatController>().bindClient(imClient);

    // // 全局订阅（也可以按 topic 订阅）
    // final subAll = imClient.subscribeAll((msg) {
    //   print('收到消息: $msg');
    // });

    // 建立连接
    await imClient.connect();

    // // 发送（如果此时未连接，消息会被缓冲并在连接后自动发送）
    // await imClient.send({'topic': 'auth', 'token': 'your_token'});
    //
    // // 按 topic 订阅
    // final chatSub = imClient.subscribeTopic('chat', (msg) {
    //   print('聊天消息: $msg');
    // });
    //
    // // 断开连接并禁止自动重连
    // await imClient.disconnect();
    //
    // // 释放资源（不可再用）
    // await imClient.dispose();
  }

  Future<void> _refreshToken(int minutes) async {
    final refreshInterval = Duration(minutes: minutes > 1 ? minutes - 1 : 1);
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      print("刷新token...");
      //刷新token
      final response = await get(pathRefreshToken());
      if (response.statusCode != HttpStatus.ok) {
        Toast.showToast("令牌即将过期，稍后请重新登录", type: ToastType.warning);
      }
    });
  }
}
