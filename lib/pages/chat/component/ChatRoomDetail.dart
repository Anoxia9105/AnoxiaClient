import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/pages/chat/component/widget/ChatAppBar.dart';
import 'package:notepadclient/pages/chat/component/widget/ChatInputField.dart';
import 'package:notepadclient/pages/chat/component/widget/ChatMessageBubble.dart';

import '../../../framework/services/room_list_service.dart';
import '../../../framework/services/room_message_service.dart';

class ChatRoomDetail extends ConsumerStatefulWidget {
  const ChatRoomDetail({super.key});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeRoomIdProvider);
    final messages = ref.watch(
      chatMessagesProvider.select((map) => map[activeId] ?? []),
    );

    return Scaffold(
      appBar: ChatAppBar(),
      body: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[messages.length - 1 - index];
          return ChatMessageBubble(message: msg);
        },
      ),
      bottomNavigationBar: ChatInputField(),
    );
  }
}