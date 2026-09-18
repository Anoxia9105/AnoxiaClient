import 'package:anoxia/framework/domain/captcha_model.dart';
import 'package:anoxia/framework/domain/scan_login_model.dart';
import 'package:anoxia/framework/domain/user_info.dart';

/// 认证仓库抽象接口
///
/// 定义用户认证相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，领域层（用例）和 UI 层（Provider）
/// 仅依赖此接口。
abstract interface class AuthRepository {
  /// 用户登录
  ///
  /// 返回服务端下发的 Token；登录失败（无 Token）时返回 null。
  Future<String?> login({
    required String account,
    required String password,
    required String code,
    required String uuid,
    required String deviceId,
  });

  /// OAuth 登录（Web/桌面 Google 登录）
  ///
  /// [provider] 目前仅 `google`；[code]/[codeVerifier]/[redirectUri] 为
  /// 系统浏览器授权流程产物，服务端用其换取身份并签发站内 Token。
  /// 返回服务端下发的 Token；失败时抛出异常。
  Future<String?> loginWithOAuth({
    required String provider,
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String deviceId,
  });

  /// 发送注册邮箱验证码
  ///
  /// 返回后端消息文本；失败时抛出异常。
  Future<String> sendRegisterEmailCode({
    required String email,
    required String captchaCode,
    required String uuid,
  });

  /// 校验注册邮箱验证码
  ///
  /// 成功时返回短期注册凭证 Token；失败时抛出异常。
  Future<String> verifyRegisterEmailCode({
    required String email,
    required String emailCode,
  });

  /// 用户注册
  ///
  /// 返回后端消息文本；失败时抛出异常。
  Future<String> register({
    required String username,
    required String email,
    required String emailVerificationToken,
    required String password,
  });

  /// 忘记密码 - 发送邮箱验证码
  ///
  /// 返回后端消息文本；失败时抛出异常。
  Future<String> forgotPasswordSendCode({
    required String email,
    required String captchaCode,
    required String uuid,
  });

  /// 忘记密码 - 校验邮箱验证码
  ///
  /// 成功时返回短期重置凭证 Token；失败时抛出异常。
  Future<String> forgotPasswordVerifyCode({
    required String email,
    required String emailCode,
  });

  /// 忘记密码 - 重置密码
  ///
  /// 返回后端消息文本；失败时抛出异常。
  Future<String> forgotPasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  });

  /// 获取当前用户信息
  Future<UserInfo?> fetchUserInfo();

  /// 获取图形验证码
  Future<CaptchaModel> fetchCaptcha();

  /// 创建扫码登录会话
  Future<ScanLoginTicket> createScanLogin();

  /// 查询扫码登录会话状态
  Future<ScanLoginStatus> getScanLoginStatus(String ticket);

  /// 手机端确认扫码登录
  Future<void> confirmScanLogin(String ticket, {required String deviceId});

  /// 用户登出
  ///
  /// [token] 可选的登录 Token，用于手动登出时携带 Authorization 头。
  Future<void> logout({String? token});

  /// 绑定/刷新推送设备标识
  Future<void> bindPushDevice(Map<String, dynamic> payload);

  /// 解绑推送设备
  ///
  /// [deviceUid] 设备唯一标识
  /// [token] 可选的登录 Token，用于解绑时携带 Authorization 头。
  Future<void> unbindPushDevice(String deviceUid, {String? token});
}
