import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/features/layout/widgets/LayoutHeader.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';
import 'package:notepadclient/shared/widgets/AcrylicContainer.dart';

/// 登录页面（带验证码）
///
/// 作者: anoxia
/// 版本: 1.1.0
/// 创建时间: 2025-09-16
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  String? _captchaBase64; // 验证码图片 Base64
  bool _loadingCaptcha = false;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  /// 模拟加载验证码（实际应调用后端接口）
  Future<void> _loadCaptcha() async {
    setState(() => _loadingCaptcha = true);
    try {
      // TODO: 替换为你的后端 API 调用
      // final res = await DioClient().get('/auth/captcha', auth: false);
      // _captchaBase64 = res.data['image_base64'];

      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
      _captchaBase64 = null; // 这里填你的 Base64 数据
    } finally {
      setState(() => _loadingCaptcha = false);
    }
  }

  void _onLogin() {
    // TODO: 调用登录 API
    // email: _emailController.text
    // password: _passwordController.text
    // captcha: _captchaController.text
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    return AcrylicContainer(
      blurSigma: 10,
      background: TweenAnimationBuilder(
        tween: ColorTween(begin: Colors.blue, end: Colors.purple),
        duration: const Duration(seconds: 5),
        onEnd: () {}, // 可以循环
        builder: (context, Color? color, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color ?? Colors.blue, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        },
      ),

      child: Container(
        // decoration: BoxDecoration(gradient: gradient),
        child: Scaffold(
          appBar: LayoutHeader().getAppbar(),
          body: SafeArea(child: Text("data")),
        ),
      ),
    );
  }
}
