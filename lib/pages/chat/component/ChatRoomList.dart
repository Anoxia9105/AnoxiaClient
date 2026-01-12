import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatRoomList extends ConsumerWidget {
  const ChatRoomList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0, // 让内容更贴近左右边缘，可按需去掉
        title: Row(
          children: [
            // 左侧搜索框
            Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // decoration: BoxDecoration(
                //   color: Colors.white.withOpacity(0.1),
                //   borderRadius: BorderRadius.circular(20),
                // ),
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    hintStyle: TextStyle(fontSize: 14),
                    hintText: '搜索',
                  ),
                ),
              ),
            ),
            // 右侧按钮
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: 按钮点击逻辑
              },
            ),
          ],
        ),
      ),
      body: Container(), // 其他内容
    );
  }
}
