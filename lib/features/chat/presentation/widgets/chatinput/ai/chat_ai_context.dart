import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 在用户主动请求时快照当前房间的已加载消息，不读取其他会话。
String captureChatAiContext(BuildContext context, String roomId) {
  final container = ProviderScope.containerOf(context, listen: false);
  final quoted = container.read(replyTargetProvider(roomId));
  return jsonEncode({
    if (quoted?.roomId == roomId)
      'quotedMessage': String.fromCharCodes(
        messagePlainText(quoted!).runes.take(500),
      ),
    'conversation': buildChatAiContext(
      (container.read(roomMessagesProvider(roomId)).value ?? const [])
          .where((message) => message.roomId == roomId)
          .toList(),
      myUserId: container.read(authControllerProvider).value?.userId.toString(),
      focusMessageId: quoted?.messageId,
    ),
  });
}
