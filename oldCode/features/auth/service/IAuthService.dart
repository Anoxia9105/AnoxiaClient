import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';

abstract class IAuthService{
  /// 获取验证码
  ///
  Future<Captcha> getCaptchaImage();

  /// 登录接口 获取用户信息
  ///
  ///参数:
  ///- [loginData] 登录参数
  Future<SysUser?> login({Map<String,String>? loginData,autoLogin = false});

  /// 退出登錄
  ///
  Future<void> logout();
}