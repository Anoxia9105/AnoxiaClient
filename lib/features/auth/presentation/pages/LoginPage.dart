
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/Validators.dart';
import '../../../../core/di/injector.dart';
import '../../domain/usecases/LoginUseCase.dart';

/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:41
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final login = getIt<LoginUseCase>();
      final user = await login(_emailCtrl.text, _pwdCtrl.text);
      // 登录成功 -> 跳转首页
      // Navigator.pushReplacement(...);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome ${user.name}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("appTitle".tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: "email".tr()),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "password".tr()),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text("login".tr()),
            ),

            DropdownButton<Locale>(
              value: context.locale,
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text("English")),
                DropdownMenuItem(value: Locale('zh'), child: Text("中文")),
                DropdownMenuItem(value: Locale('ja'), child: Text("日本語")),
              ],
              onChanged: (locale) {
                if (locale != null) {
                  context.setLocale(locale);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
