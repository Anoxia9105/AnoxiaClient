// 编辑目标消息管理
//
// 维护各房间当前正在编辑的目标消息，支持按房间 ID 设置和清除编辑目标；
// 并集中「消息可编辑」的判定口径（本人 + Text/RichText + 服务端同款 15 分钟窗口）。
import 'dart:convert';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑窗口：与服务端固定口径一致（消息时间戳起算 15 分钟）
const Duration chatEditWindow = Duration(minutes: 15);

/// 消息是否支持编辑（协议约定：仅本人 + Text/RichText 负载 + 窗口内）
///
/// 富文本里带图片/文件等 embed 的消息无法在输入框忠实重放（需要重新上传），
/// 同样不支持编辑。
bool canEditMessage(ChatMessage message, int? currentUserId) {
  if (currentUserId == null || message.senderId != currentUserId) return false;
  if (message.deliveryStatus != DeliveryStatus.sent) return false;
  final messageId = message.messageId;
  if (messageId == null || messageId.isEmpty) return false;
  return _isEditablePayload(message) && _withinEditWindow(message);
}

bool _isEditablePayload(ChatMessage message) {
  switch (message.messageType) {
    case MessageType.text:
      return true;
    case MessageType.richText:
      return !_richTextHasEmbeds(message);
    default:
      return false;
  }
}

bool _withinEditWindow(ChatMessage message) {
  final timestamp = message.timestamp;
  if (timestamp == null || timestamp <= 0) return false;
  return DateTime.now().millisecondsSinceEpoch - timestamp <=
      chatEditWindow.inMilliseconds;
}

bool _richTextHasEmbeds(ChatMessage message) {
  final deltaJson = message.payload?.quillDelta;
  if (deltaJson == null || deltaJson.isEmpty) return false;
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! Map) return true; // 结构异常时宁可少给入口
    final ops = decoded['ops'];
    if (ops is! List) return true;
    return ops.any((op) {
      if (op is! Map) return true;
      return op['insert'] is! String;
    });
  } catch (_) {
    return true;
  }
}

/// 编辑目标控制器
///
/// 以房间 ID 为 key 管理每个房间的编辑目标消息。
class EditTargetController extends Notifier<Map<String, ChatMessage?>> {
  @override
  Map<String, ChatMessage?> build() => {};

  /// 设置指定房间的编辑目标消息
  ///
  /// [roomId] 房间 ID
  /// [message] 要编辑的目标消息
  void set(String roomId, ChatMessage message) {
    state = {...state, roomId: message};
  }

  /// 清除指定房间的编辑目标消息
  ///
  /// [roomId] 房间 ID
  void clear(String roomId) {
    if (!state.containsKey(roomId)) return;
    final next = {...state}..remove(roomId);
    state = next;
  }
}

/// 编辑目标控制器 Provider
final editTargetControllerProvider =
    NotifierProvider<EditTargetController, Map<String, ChatMessage?>>(
      EditTargetController.new,
    );

/// 按房间 ID 获取编辑目标消息的 Provider
final editTargetProvider = Provider.family<ChatMessage?, String>(
  (ref, roomId) => ref.watch(editTargetControllerProvider)[roomId],
);
