import 'dart:convert';

import 'package:anoxia/framework/extensions/window_controller.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';

import 'RoomPage.dart'; // 确保这里引入了你刚才写的 RoomPage

const _channel = WindowMethodChannel('example_video_player_window');

class NotCodePage extends StatefulWidget {
  const NotCodePage({super.key});

  @override
  State<NotCodePage> createState() => _NotCodePageState();
}

class _NotCodePageState extends State<NotCodePage> {
  // 1. 创建控制器来获取输入框的内容
  final TextEditingController _tokenController = TextEditingController();

  // 定义服务器地址 (你可以根据需要改成输入框)
  final String _url = "ws://8.137.14.21:7880";

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      print('主窗口收到方法调用: ${call.method} ${call.arguments}');
      return '主窗口返回';
    });
  }

  @override
  void dispose() {
    // 记得销毁控制器

    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 加上 Scaffold 避免键盘弹出时的布局问题
      appBar: AppBar(title: const Text("连接测试")),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // 加点边距，好看一点
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () async {
                // Create a new window
                final controller = await WindowController.create(
                  WindowConfiguration(
                    hiddenAtLaunch: true,
                    arguments: jsonEncode({
                      'room': "testroom",
                      'themeIndex': 4,
                      'userinfo': {'id': 1, 'name': "abc"},
                    }),
                  ),
                );

                // Show the window (if hidden at launch)
                Future.delayed(Duration(seconds: 1), () async {
                  await controller.show();
                });
              },
              icon: Icon(Icons.add),
            ),
            IconButton(
              onPressed: () async {
                final result = await _channel.invokeMethod('play');
                print('main结果: $result');
                final controllers = WindowController.getAll();
                for (var controller in await controllers) {
                  await controller.center();
                }
              },
              icon: Icon(Icons.send),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedDocumentCode,
              color: Colors.blueAccent,
              size: 64.0,
            ),
            const SizedBox(height: 16),
            const Text(
              "请输入连接凭证",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 2. 添加输入框
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: "Token",
                hintText: "粘贴你的 LiveKit Token",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              maxLines: 3, // Token 通常很长，给它多几行显示
              minLines: 1,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text("开始连接"),
              onPressed: () async {
                // 3. 获取输入框的 Token
                final token = _tokenController.text.trim();

                if (token.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Token 不能为空！')));
                  return;
                }

                // --- 连接逻辑开始 ---
                try {
                  // 显示加载提示（可选优化）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正在连接服务器...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  final roomOptions = RoomOptions(
                    adaptiveStream: true,
                    dynacast: true,
                  );

                  final room = Room(roomOptions: roomOptions);

                  // 使用输入的 URL 和 Token
                  await room.prepareConnection(_url, token);
                  await room.connect(_url, token);

                  // 2. 默认关闭摄像头 (显式调用 false，确保状态一致)
                  try {
                    await room.localParticipant?.setCameraEnabled(false);
                  } catch (e) {
                    debugPrint('关闭摄像头操作失败: $e');
                  }

                  // 3. 仅开启麦克风
                  try {
                    await room.localParticipant?.setMicrophoneEnabled(true);
                  } catch (e) {
                    // 如果用户拒绝了麦克风权限，这里会捕获异常
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('麦克风开启失败，请检查权限: $e')),
                      );
                    }
                  }
                  // 跳转页面
                  // if (context.mounted) {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => RoomPage(room: room),
                  //     ),
                  //   );
                  // }
                } catch (e) {
                  // 错误处理
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('连接失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  print(e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
