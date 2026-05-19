
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_list_item_skeleton.dart';
import 'package:flutter/material.dart';

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