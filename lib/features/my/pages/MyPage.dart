import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/core/utils/AesGcmUtils.dart';
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AuthController authController = getIt<AuthController>();
  final IMClient imClient = getIt<IMClient>();
  Uint8List? key;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    String? secret = await SSUtil.instance.read(key: StorageKeys.secret);
    if (secret != null) {
      key = utf8.encode('GBzC9cana09U1Cp6');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton(
          onPressed: () => authController.logout(context),
          child: Text("退出登录"),
        ),
        FilledButton(
          onPressed: () async {
            if (key == null) return;
            String content = """
                        {
                "type":"MESSAGE_DATA",
                "data":{
                  "roomId":"testroom2",
                  "messageId":"msg-202508291620001",
                  "type":"CONTENT",
                  "payload":{
                    "type":"QUILL",
                    "text":"你好"
                    }
                  }
                }
        """;

            String msg = await AesGcmUtils.encrypt(content, key!);
            imClient.send(msg);
          },
          child: Text("测试发消息"),
        ),
      ],
    );
  }
}
