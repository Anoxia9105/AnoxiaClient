import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/pages/AppScaffold.dart';

import '../framework/provider/core/app_initializer.dart';

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
    final loginMutation = ref.watch(AuthController.loginMutation);

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
                  ref
                      .watch(getCaptchaProvider)
                      .when(
                        data: (captcha) {
                          return InkWell(
                            onTap: () => ref.invalidate(getCaptchaProvider),
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
                          onPressed: () => ref.invalidate(getCaptchaProvider),
                        ),
                      ),
                ],
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: switch (loginMutation) {
                  MutationPending() => null,
                  _ => login,
                },
                icon: const Icon(Icons.door_front_door),
                label: switch (loginMutation) {
                  MutationPending() => const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  _ => const Text('Login'),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
    final captcha = ref.read(getCaptchaProvider).value;
    if (captcha == null) return;
    await AuthController.loginMutation.run(ref, (ref) {
      return ref
          .get(authControllerProvider.notifier)
          .login(
            usernameCtrl.text.trim(),
            passwordCtrl.text.trim(),
            codeCtrl.text.trim(),
            captcha.uuid,
          );
    });

    // 登录成功后，重置初始化状态，重新加载应用数据
    await ref.read(appInitializerProvider.notifier).performFullReset();
  }
}
