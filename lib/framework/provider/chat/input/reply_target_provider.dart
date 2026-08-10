// 回复目标消息管理
//
// 维护各房间当前正在回复的目标消息，支持按房间 ID 设置和清除回复目标。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 回复目标控制器
///
/// 以房间 ID 为 key 管理每个房间的回复目标消息。
class ReplyTargetController extends Notifier<Map<String, ChatMessage?>> {
  @override
  Map<String, ChatMessage?> build() => {};

  /// 设置指定房间的回复目标消息
  ///
  /// [roomId] 房间 ID
  /// [message] 要回复的目标消息
  void set(String roomId, ChatMessage message) {
    state = {...state, roomId: message};
  }

  /// 清除指定房间的回复目标消息
  ///
  /// [roomId] 房间 ID
  void clear(String roomId) {
    if (!state.containsKey(roomId)) return;
    final next = {...state}..remove(roomId);
    state = next;
  }
}

/// 回复目标控制器 Provider
final replyTargetControllerProvider =
    NotifierProvider<ReplyTargetController, Map<String, ChatMessage?>>(
      ReplyTargetController.new,
    );

/// 按房间 ID 获取回复目标消息的 Provider
final replyTargetProvider = Provider.family<ChatMessage?, String>(
  (ref, roomId) =>
      ref.watch(replyTargetControllerProvider.select((state) => state[roomId])),
);
