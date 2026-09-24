import 'dart:async';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/auth_repository.dart';
import 'package:anoxia/framework/domain/captcha_model.dart';
import 'package:anoxia/framework/domain/scan_login_model.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/domain/auth_login_result.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:dio/dio.dart';

/// 认证仓库实现
///
/// 通过远程数据源（HTTP API）提供用户认证相关操作。
/// 实现 [AuthRepository] 抽象接口，供领域层用例和 UI 层 Provider 使用。
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthLoginResult?> login({
    required String account,
    required String password,
    required String code,
    required String uuid,
    required String deviceId,
  }) async {
    final res = await DioClient().post(
      API.login,
      data: {
        'username': account,
        'password': password,
        'code': code,
        'uuid': uuid,
        'deviceId': deviceId,
      },
      auth: false,
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '登录失败'));
    }
    return _parseLoginResult(res.data);
  }

  @override
  Future<bool> isGuestLoginEnabled() async {
    final res = await DioClient().get(API.guestLoginConfig, auth: false);
    return res.data is Map && res.data['data'] is Map
        ? res.data['data']['enabled'] == true
        : false;
  }

  @override
  Future<AuthLoginResult> createGuest({required String deviceId}) async {
    final res = await DioClient().post(
      API.guestLogin,
      data: {'deviceId': deviceId, 'platform': 'web'},
      auth: false,
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '游客登录失败'));
    }
    return _parseLoginResult(res.data) ??
        (throw Exception(_extractApiMsg(res.data, fallback: '游客登录失败')));
  }

  @override
  Future<AuthLoginResult> quickLogin({
    required int userId,
    required String credential,
    required String deviceId,
  }) async {
    final res = await DioClient().post(
      API.quickLogin,
      data: {
        'userId': userId,
        'credential': credential,
        'deviceId': deviceId,
      },
      auth: false,
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '快速登录失败'));
    }
    return _parseLoginResult(res.data) ??
        (throw Exception(_extractApiMsg(res.data, fallback: '快速登录失败')));
  }

  @override
  Future<AuthLoginResult?> loginWithOAuth({
    required String provider,
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String deviceId,
  }) async {
    final res = await DioClient().post(
      API.loginOAuth,
      data: {
        'provider': provider,
        'code': code,
        'codeVerifier': codeVerifier,
        'redirectUri': redirectUri,
        'deviceId': deviceId,
      },
      auth: false,
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '第三方登录失败'));
    }
    return _parseLoginResult(res.data);
  }

  @override
  Future<String> sendRegisterEmailCode({
    required String email,
    required String captchaCode,
    required String uuid,
  }) async {
    final res = await DioClient().post(
      API.registerSendEmailCode,
      data: {'email': email, 'code': captchaCode, 'uuid': uuid},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    return msg;
  }

  @override
  Future<String> verifyRegisterEmailCode({
    required String email,
    required String emailCode,
  }) async {
    final res = await DioClient().post(
      API.registerVerifyEmailCode,
      data: {'email': email, 'emailCode': emailCode},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '邮箱验证失败');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    final token = res.data is Map ? res.data['data']?.toString() : null;
    if (token == null || token.isEmpty) throw Exception('邮箱验证凭证无效');
    return token;
  }

  @override
  Future<String> register({
    required String username,
    required String email,
    required String emailVerificationToken,
    required String password,
  }) async {
    final res = await DioClient().post(
      API.register,
      data: {
        'username': username,
        'email': email,
        'emailVerificationToken': emailVerificationToken,
        'password': password,
      },
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '注册成功');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    return msg;
  }

  @override
  Future<String> forgotPasswordSendCode({
    required String email,
    required String captchaCode,
    required String uuid,
  }) async {
    final res = await DioClient().post(
      API.forgotPasswordSendCode,
      data: {'email': email, 'captchaCode': captchaCode, 'uuid': uuid},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) {
      throw Exception(msg);
    }
    return msg;
  }

  @override
  Future<String> forgotPasswordVerifyCode({
    required String email,
    required String emailCode,
  }) async {
    final res = await DioClient().post(
      API.forgotPasswordVerifyCode,
      data: {'email': email, 'emailCode': emailCode},
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '邮箱验证失败');
    if (!_isApiSuccess(res.data)) throw Exception(msg);
    final token = res.data is Map ? res.data['data']?.toString() : null;
    if (token == null || token.isEmpty) throw Exception('邮箱验证凭证无效');
    return token;
  }

  @override
  Future<String> forgotPasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await DioClient().post(
      API.forgotPasswordReset,
      data: {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      auth: false,
    );
    final msg = _extractApiMsg(res.data, fallback: '操作成功');
    if (!_isApiSuccess(res.data)) {
      throw Exception(msg);
    }
    return msg;
  }

  @override
  Future<UserInfo?> fetchUserInfo() async {
    final res = await DioClient().get(API.getInfo);
    return UserInfo.fromJson(res.data['data']);
  }

  @override
  Future<CaptchaModel> fetchCaptcha() async {
    final res = await DioClient().get(API.captchaImage, auth: false);
    return CaptchaModel(uuid: res.data['uuid'], imgBase64: res.data['img']);
  }

  @override
  Future<ScanLoginTicket> createScanLogin() async {
    final res = await DioClient().post(API.scanLoginCreate, auth: false);
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '创建扫码登录失败'));
    }
    final body = res.data;
    if (body is! Map) throw Exception('创建扫码登录失败');
    return ScanLoginTicket(
      ticket: body['ticket']?.toString() ?? '',
      qrContent: body['qrContent']?.toString() ?? '',
      expiresIn: (body['expiresIn'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<ScanLoginStatus> getScanLoginStatus(String ticket) async {
    final res = await DioClient().get(
      '${API.scanLoginStatus}?ticket=${Uri.encodeQueryComponent(ticket)}',
      auth: false,
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '查询扫码登录状态失败'));
    }
    final body = res.data;
    if (body is! Map) throw Exception('查询扫码登录状态失败');
    final token = body['token']?.toString();
    return ScanLoginStatus(
      status: body['status']?.toString() ?? ScanLoginStatus.expired,
      token: (token == null || token.isEmpty) ? null : token,
    );
  }

  @override
  Future<void> confirmScanLogin(
    String ticket, {
    required String deviceId,
  }) async {
    final res = await DioClient().post(
      API.scanLoginConfirm,
      data: {'ticket': ticket, 'deviceId': deviceId},
    );
    if (!_isApiSuccess(res.data)) {
      throw Exception(_extractApiMsg(res.data, fallback: '扫码登录确认失败'));
    }
  }

  @override
  Future<void> logout({String? token}) async {
    try {
      await DioClient()
          .post(
            API.logout,
            auth: false,
            options: Options(
              headers: {
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              },
            ),
          )
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugLog('[Auth] 后端登出请求失败（忽略）: $e');
    }
  }

  @override
  Future<void> bindPushDevice(Map<String, dynamic> payload) async {
    await DioClient().post(API.pushDeviceBind, data: payload);
  }

  @override
  Future<void> unbindPushDevice(String deviceUid, {String? token}) async {
    await DioClient().delete(
      '${API.pushDeviceUnbind}?deviceUid=${Uri.encodeQueryComponent(deviceUid)}',
      auth: false,
      options: Options(
        extra: {'skipAuthFailureLogout': true},
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  bool _isApiSuccess(dynamic body) {
    if (body is! Map) return true;

    final code = body['code'];
    if (code is num) return code == 200;
    if (code is String) return code == '200' || code == '0';

    final nestedData = body['data'];
    if (nestedData is Map) {
      final nestedCode = nestedData['code'];
      if (nestedCode is num) return nestedCode == 200;
      if (nestedCode is String) return nestedCode == '200' || nestedCode == '0';
    }

    return true;
  }

  String _extractApiMsg(dynamic body, {required String fallback}) {
    if (body is! Map) return fallback;

    final msg = body['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();

    final nestedData = body['data'];
    if (nestedData is Map) {
      final nestedMsg = nestedData['msg'];
      if (nestedMsg is String && nestedMsg.trim().isNotEmpty) {
        return nestedMsg.trim();
      }
    }

    return fallback;
  }

  AuthLoginResult? _parseLoginResult(dynamic body) {
    if (body is! Map) return null;
    final token = body['token']?.toString() ?? '';
    if (token.isEmpty) return null;
    return AuthLoginResult(
      token: token,
      quickLoginCredential: body['quickLoginCredential']?.toString() ?? '',
      firstGuestLogin: body['firstGuestLogin'] == true,
    );
  }
}
