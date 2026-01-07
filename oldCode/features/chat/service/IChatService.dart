import 'package:notepadclient/core/domain/RoomSummary.dart';

abstract class IChatService {
  /// 获取聊天列表
  ///
  /// 参数:
  /// - [userId] 用户ID
  Future<List<RoomSummary>> getChatList(num? userId);

  /// 获取聊天消息 带分页
  ///
  /// 参数:
  /// - [roomId] 聊天室ID

  Future<void> getRoomMessage(String roomId,num userId);
}