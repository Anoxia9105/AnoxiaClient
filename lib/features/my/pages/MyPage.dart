import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AuthController authController = getIt<AuthController>();
  final IMClient imClient = getIt<IMClient>();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FilledButton(onPressed: ()=>authController.logout(context), child: Text("退出")),
      FilledButton(onPressed: ()=>imClient.connect(), child: Text("连接"))
    ],);
  }
}
