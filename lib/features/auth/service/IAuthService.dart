import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';

abstract class IAuthService{
  /// 获取验证码
  ///
  Future<Captcha> getCaptchaImage();

  /// 登录接口 获取token
  ///
  ///参数:
  ///- [loginData] 登录参数
  Future<SysUser?> loginByToken(Map<String,String> loginData);
}