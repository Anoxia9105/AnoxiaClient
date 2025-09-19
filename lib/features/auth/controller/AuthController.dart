/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:42
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';

import '../../../core/di/injector.dart';
import '../../../shared/widgets/FocusOverlayManager.dart';
import '../service/IAuthService.dart';

IAuthService authService = getIt<IAuthService>();
LayoutController layoutController = getIt<LayoutController>();

class AuthController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLogin = false;
  Uint8List? bytes;
  bool obscure = true;
  late Captcha captcha;

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

  void login(BuildContext context) {
    FocusOverlayManager.show(
      context,
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(),
            Text("login ...${captcha.code}--${captcha.uuid}--${captcha.msg}")],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 10), () {
      FocusOverlayManager.hide();
      layoutController.login = true;
    });
  }
}
