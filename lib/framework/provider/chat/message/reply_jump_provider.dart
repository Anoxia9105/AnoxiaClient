import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReplyJumpRequest {
  final String roomId;
  final String messageId;
  final int nonce;

  const ReplyJumpRequest({
    required this.roomId,
    required this.messageId,
    required this.nonce,
  });
}

class ReplyJumpController extends Notifier<ReplyJumpRequest?> {
  int _nonce = 0;

  @override
  ReplyJumpRequest? build() => null;

  void jumpTo({required String roomId, required String messageId}) {
    if (roomId.isEmpty || messageId.isEmpty) return;
    state = ReplyJumpRequest(
      roomId: roomId,
      messageId: messageId,
      nonce: ++_nonce,
    );
  }
}

final replyJumpControllerProvider =
    NotifierProvider<ReplyJumpController, ReplyJumpRequest?>(
      ReplyJumpController.new,
    );
