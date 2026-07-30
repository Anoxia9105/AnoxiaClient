import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReplyTargetController extends Notifier<Map<String, ChatMessage?>> {
  @override
  Map<String, ChatMessage?> build() => {};

  void set(String roomId, ChatMessage message) {
    state = {...state, roomId: message};
  }

  void clear(String roomId) {
    if (!state.containsKey(roomId)) return;
    final next = {...state}..remove(roomId);
    state = next;
  }
}

final replyTargetControllerProvider =
    NotifierProvider<ReplyTargetController, Map<String, ChatMessage?>>(
      ReplyTargetController.new,
    );

final replyTargetProvider = Provider.family<ChatMessage?, String>(
  (ref, roomId) =>
      ref.watch(replyTargetControllerProvider.select((state) => state[roomId])),
);
