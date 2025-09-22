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
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';


import '../../../core/di/injector.dart';
import '../../../shared/widgets/FocusOverlayManager.dart';
import '../service/IAuthService.dart';

IAuthService authService = getIt<IAuthService>();
LayoutController layoutController = getIt<LayoutController>();

class AuthController extends ChangeNotifier {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLogin = false;
  Uint8List? bytes;
  bool obscure = true;
  late Captcha captcha;

  late final SysUser userInfo;

  setObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  Future<void> loadCaptcha() async {
    captcha = await authService.getCaptchaImage();
    if (captcha.code == 200 && captcha.img != null) {
      bytes = base64Decode(captcha.img!);
      notifyListeners();
    }
  }

  Future<void> login(BuildContext context) async {
    isLogin = true;
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
      }
    } catch (e, t) {
      print("登录失败: $e,$t");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("登录失败，请检查信息或稍后重试")));
    } finally {
      FocusOverlayManager.hide();
      isLogin = false;
    }
  }
}
