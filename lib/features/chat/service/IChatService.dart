import 'package:notepadclient/core/domain/RoomSummary.dart';

abstract class IChatService {
  /// 获取聊天列表
  ///
  /// 参数:
  /// - [userId] 用户ID
  Future<RoomSummary?> getChatList(num? userId);
}