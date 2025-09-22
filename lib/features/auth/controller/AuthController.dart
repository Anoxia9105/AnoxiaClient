/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:42
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';

import '../../../core/di/injector.dart';
import '../../../shared/widgets/FocusOverlayManager.dart';
import '../service/IAuthService.dart';

IAuthService authService = getIt<IAuthService>();
LayoutController layoutController = getIt<LayoutController>();

class AuthController extends ChangeNotifier {
  AuthController() {
    _init();
  }

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  //登录按钮限流
  bool onLogin = false;
  //自动登录
  bool autoLogin=false;

  Uint8List? bytes;
  bool obscure = true;
  late Captcha captcha;

  SysUser? userInfo;

  ///密码是否可见
  ///
  setObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  ///自动登录
  ///
  Future<void> _init() async {
    autoLogin=true;
    final token = await SSUtil.instance.read(key: StorageKeys.accessToken);
    SysUser? user = await authService.getUserInfo();

    if (token != null && token.isNotEmpty && user != null) {
      // token 有效，直接进入已登录状态
      layoutController.login = true;
      userInfo = user;
      authService.connect(token);
    } else {
      layoutController.login = false;
      autoLogin=false;
      loadCaptcha();
    }
  }

  ///
  /// 加载验证码
  Future<void> loadCaptcha() async {
    captcha = await authService.getCaptchaImage();
    if (captcha.code == 200 && captcha.img != null) {
      bytes = base64Decode(captcha.img!);
      notifyListeners();
    }
  }

  ///用户登录
  ///
  Future<void> login(BuildContext context) async {
    onLogin = true;
    FocusOverlayManager.show(
      context,
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("登录中，请稍候..."),
          ],
        ),
      ),
    );
    try {
      var user = await authService.loginByToken({
        "username": nameController.text.trim(),
        "password": passwordController.text.trim(),
        "code": captchaController.text.trim(),
        "uuid": ?captcha.uuid,
      });
      if (user != null && user.code == HttpStatus.ok) {
        userInfo = user;
        layoutController.login = true;
      } else {
        //刷新验证码
        loadCaptcha();
        //清空验证码
        captchaController.clear();
      }
    } catch (e, t) {
      print("登录失败: $e,$t");
    } finally {
      FocusOverlayManager.hide();
      onLogin = false;
    }
  }

  /// 用户登出
  Future<void> logout(BuildContext context) async {
    try {
      await authService.logout();

      // 清除本地存储的 token 和用户信息
      await SSUtil.instance.delete(key: StorageKeys.accessToken);
      await SPUtil.instance.remove(StorageKeys.sysUser);

      // 重置状态
      layoutController.login = false;
      onLogin = false;
      captchaController.clear();
      nameController.clear();
      passwordController.clear();

      // 清空用户信息
      userInfo = null;

      loadCaptcha();

      notifyListeners();
    } catch (e, t) {
      print("登出失败: $e, $t");
    }
  }
}
