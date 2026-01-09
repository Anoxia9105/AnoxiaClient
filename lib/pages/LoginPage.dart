import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/provider/auth/auth_controller.dart';
import 'package:notepadclient/framework/services/auth_service.dart';
import 'package:notepadclient/pages/AppScaffold.dart';

import '../framework/theme/AppColors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final captchaAsync = ref.watch(captchaProvider);

    return AppScaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "登录",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(labelText: "用户名"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: "密码"),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(labelText: "验证码"),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 验证码图片
                  captchaAsync.when(
                    data: (captcha) {
                      return InkWell(
                        onTap: () => ref.invalidate(captchaProvider),
                        child: Image.memory(
                          base64Decode(captcha.imgBase64),
                          width: 100,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    loading: () => SizedBox(
                      width: 100,
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(captchaProvider),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: () async {
                  final captcha = ref.read(captchaProvider).value;
                  if (captcha == null) return;

                  await ref
                      .read(authControllerProvider.notifier)
                      .login(
                        usernameCtrl.text.trim(),
                        passwordCtrl.text.trim(),
                        codeCtrl.text.trim(),
                        captcha.uuid,
                      );
                },
                child: Text("登录"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
