import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../framework/domain/AiChatMessage.dart';
import '../../framework/provider/ai/ai_chat_controller.dart';


class AIChatPage extends ConsumerWidget {
  AIChatPage({super.key});

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(aiChatControllerProvider);
    final isGenerating =
        messages.isNotEmpty && messages.last.isStreaming;

    return Scaffold(
      appBar: AppBar(title: const Text("Gemini Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => _bubble(messages[i]),
            ),
          ),
          _inputArea(ref, isGenerating),
        ],
      ),
    );
  }

  Widget _bubble(AiChatMessage msg) {
    return Align(
      alignment:
      msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isAi ? Colors.grey[200] : Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.content.isEmpty && msg.isStreaming
              ? "AI 正在思考..."
              : msg.content,
        ),
      ),
    );
  }

  Widget _inputArea(WidgetRef ref, bool isGenerating) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isGenerating,
              decoration:
              const InputDecoration(hintText: "问问 Gemini..."),
            ),
          ),
          IconButton(
            icon: Icon(
              isGenerating ? Icons.stop_circle : Icons.send,
            ),
            color: isGenerating ? Colors.red : Colors.blue,
            onPressed: () {
              final notifier =
              ref.read(aiChatControllerProvider.notifier);

              if (isGenerating) {
                notifier.stopGenerating();
              } else if (_controller.text.isNotEmpty) {
                notifier.askGemini(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
