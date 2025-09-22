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

  /// 获取用户信息
  ///
  Future<SysUser?> getUserInfo();

  /// token续期
  /// 参数：
  /// -[minutes] 分钟数
  Future<void> refreshToken(int minutes);

  /// 退出登錄
  ///
  Future<void> logout();

  /// 连接服务器
  ///
  Future<void> connect(String token);
}