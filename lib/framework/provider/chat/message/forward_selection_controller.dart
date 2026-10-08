import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forward_selection_controller.g.dart';

bool canForwardMessage(ChatMessage message) =>
    message.deliveryStatus == DeliveryStatus.sent &&
    (message.seq ?? 0) > 0 &&
    message.messageId?.isNotEmpty == true &&
    message.messageType != null &&
    message.messageType != MessageType.system;

class ForwardSelectionState {
  final bool active;
  final Map<String, ChatMessage> messages;
  const ForwardSelectionState({this.active = false, this.messages = const {}});
}

@riverpod
class ForwardSelectionController extends _$ForwardSelectionController {
  @override
  ForwardSelectionState build(String roomId) {
    ref.listen(activeRoomIdProvider, (previous, next) {
      if (previous == roomId && next != roomId) clear();
    });
    return const ForwardSelectionState();
  }

  void start(ChatMessage message) {
    if (!canForwardMessage(message) || message.roomId != roomId) return;
    state = ForwardSelectionState(
      active: true,
      messages: {message.messageId!: message},
    );
  }

  bool toggle(ChatMessage message) {
    if (!canForwardMessage(message) || message.roomId != roomId) return false;
    final next = {...state.messages};
    if (next.containsKey(message.messageId)) {
      next.remove(message.messageId);
    } else {
      if (next.length >= 50) return false;
      next[message.messageId!] = message;
    }
    state = ForwardSelectionState(active: true, messages: next);
    return true;
  }

  void remove(String messageId) {
    if (!state.messages.containsKey(messageId)) return;
    state = ForwardSelectionState(
      active: state.active,
      messages: {...state.messages}..remove(messageId),
    );
  }

  void clear() => state = const ForwardSelectionState();
}

typedef ForwardNavigationTarget = ({
  String roomId,
  String messageId,
  int nonce,
});

@Riverpod(keepAlive: true)
class ForwardNavigationTargetController
    extends _$ForwardNavigationTargetController {
  int _nonce = 0;
  @override
  ForwardNavigationTarget? build() => null;
  void setTarget(String roomId, String messageId) =>
      state = (roomId: roomId, messageId: messageId, nonce: ++_nonce);
  void clear() => state = null;
}
