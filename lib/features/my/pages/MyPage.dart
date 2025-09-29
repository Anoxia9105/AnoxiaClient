import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/core/utils/AesGcmUtils.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/features/chat/service/IChatService.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AuthController authController = getIt<AuthController>();

  @override
  Widget build(BuildContext context) {
    return const MessageTestPage();
  }
}

class MessageTestPage extends StatefulWidget {


  const MessageTestPage({super.key});

  @override
  _MessageTestPageState createState() => _MessageTestPageState();
}

class _MessageTestPageState extends State<MessageTestPage> {
  final TextEditingController _baseTypeController =
  TextEditingController(text: "MESSAGE_DATA");
  final TextEditingController _typeController =
  TextEditingController(text: "CONTENT");
  final TextEditingController _roomIdController =
  TextEditingController(text: "testroom2");
  final TextEditingController _messageIdController =
  TextEditingController(text: "msg-202508291620001");
  final TextEditingController _payloadTextController = TextEditingController(
    text: """
{
  "type": "QUILL",
  "text": "你好啊！"
}
""",
  );

  final IMClient imClient = getIt<IMClient>();
  final List<String> _messages = [];
  String _jsonResult = "";

  @override
  void initState() {
    super.initState();
    imClient.subscribeAll((msg) async {
      final res = await AesGcmUtils.decrypt(
        msg.data,
        utf8.encode('GBzC9cana09U1Cp6'),
      );
      setState(() => _messages.add(res));
    });
  }

  Future<void> _buildAndSendJson() async {
    try {
      final payloadObj = jsonDecode(_payloadTextController.text);

      final message = {
        "type": _baseTypeController.text,
        "data": {
          "roomId": _roomIdController.text,
          "messageId": _messageIdController.text,
          "type": _typeController.text,
          "payload": payloadObj,
        },
      };

      setState(() {
        _jsonResult = const JsonEncoder.withIndent("  ").convert(message);
      });

      final encrypted = await AesGcmUtils.encrypt(
        _jsonResult,
        utf8.encode('GBzC9cana09U1Cp6'),
      );
      imClient.send(encrypted);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("payload 不是合法 JSON")),
      );
    }
  }

  Widget _buildCard(String title, Widget child, {double heightFactor = 1}) {
    return Expanded(
      flex: (heightFactor * 10).toInt(),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("消息测试页面")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            FilledButton(onPressed: (){
              final IChatService chatService=getIt<IChatService>();
              chatService.getRoomMessage("testroom2",1);
            }, child: Text("消息数据")),
            // 输入区
            _buildCard(
              "输入参数",
              ListView(
                children: [
                  TextField(
                    controller: _baseTypeController,
                    decoration: const InputDecoration(labelText: "主类型"),
                  ),
                  TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(labelText: "消息类型"),
                  ),
                  TextField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(labelText: "房间ID"),
                  ),
                  TextField(
                    controller: _messageIdController,
                    decoration: const InputDecoration(labelText: "消息ID"),
                  ),
                  TextField(
                    controller: _payloadTextController,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: "消息内容(JSON)"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _buildAndSendJson,
                    icon: const Icon(Icons.send),
                    label: const Text("发送消息"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              heightFactor: 2.2,
            ),

            // 构建结果区
            _buildCard(
              "构建的 JSON",
              SingleChildScrollView(
                child: SelectableText(
                  _jsonResult,
                  style: const TextStyle(fontFamily: "monospace"),
                ),
              ),
              heightFactor: 1.3,
            ),

            // 接收消息区
            _buildCard(
              "接收的消息",
              ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _messages[index],
                      style: const TextStyle(fontFamily: "monospace"),
                    ),
                  );
                },
              ),
              heightFactor: 2,
            ),
          ],
        ),
      ),
    );
  }
}
