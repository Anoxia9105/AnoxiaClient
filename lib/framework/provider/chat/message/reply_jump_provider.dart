// 回复跳转功能
//
// 管理回复消息的跳转请求，通过 nonce 机制确保每次跳转都是唯一请求，避免重复触发。
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 回复跳转请求
///
/// 包含跳转所需的目标房间、消息 ID 和唯一标识 nonce。
class ReplyJumpRequest {
  /// 目标房间 ID
  final String roomId;

  /// 目标消息 ID
  final String messageId;

  /// 请求唯一标识，用于区分不同的跳转请求
  final int nonce;

  const ReplyJumpRequest({
    required this.roomId,
    required this.messageId,
    required this.nonce,
  });
}

/// 回复跳转控制器
///
/// 管理回复消息的跳转请求状态，每次调用 [jumpTo] 会生成新的请求并递增 nonce。
class ReplyJumpController extends Notifier<ReplyJumpRequest?> {
  int _nonce = 0;

  @override
  ReplyJumpRequest? build() => null;

  /// 发起跳转到指定消息的请求
  ///
  /// [roomId] 目标房间 ID，不能为空
  /// [messageId] 目标消息 ID，不能为空
  void jumpTo({required String roomId, required String messageId}) {
    if (roomId.isEmpty || messageId.isEmpty) return;
    state = ReplyJumpRequest(
      roomId: roomId,
      messageId: messageId,
      nonce: ++_nonce,
    );
  }
}

/// 回复跳转控制器 Provider
final replyJumpControllerProvider =
    NotifierProvider<ReplyJumpController, ReplyJumpRequest?>(
      ReplyJumpController.new,
    );
