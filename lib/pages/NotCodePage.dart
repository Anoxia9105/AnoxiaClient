import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import 'RoomPage.dart'; // 确保这里引入了你刚才写的 RoomPage

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
  void dispose() {
    // 记得销毁控制器
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // 加上 Scaffold 避免键盘弹出时的布局问题
      appBar: AppBar(title: const Text("LiveKit 连接测试")),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // 加点边距，好看一点
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token 不能为空！')),
                  );
                  return;
                }

                // --- 连接逻辑开始 ---
                try {
                  // 显示加载提示（可选优化）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('正在连接服务器...'), duration: Duration(seconds: 1)),
                  );

                  final roomOptions = RoomOptions(
                    adaptiveStream: true,
                    dynacast: true,
                  );

                  final room = Room();

                  // 使用输入的 URL 和 Token
                  await room.prepareConnection(_url, token);
                  await room.connect(_url, token, roomOptions: roomOptions);

                  // 开启设备
                  try {
                    await room.localParticipant?.setCameraEnabled(true);
                  } catch (error) {
                    print('摄像头开启失败 (模拟器正常现象): $error');
                  }
                  await room.localParticipant?.setMicrophoneEnabled(true);

                  // 跳转页面
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomPage(room: room),
                      ),
                    );
                  }
                } catch (e) {
                  // 错误处理
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('连接失败: $e'), backgroundColor: Colors.red),
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