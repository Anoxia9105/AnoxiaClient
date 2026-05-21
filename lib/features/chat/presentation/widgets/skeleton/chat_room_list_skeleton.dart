
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_list_item_skeleton.dart';
import 'package:flutter/material.dart';

/// 聊天房间列表骨架屏组件
///
/// 用于在房间列表加载过程中显示占位内容，
/// 包含多个 [ChatRoomListItemSkeleton] 组成的列表
class ChatRoomListSkeleton extends StatelessWidget {
  const ChatRoomListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) => ChatRoomListItemSkeleton(index: index),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemCount: 9,
    );
  }
}
