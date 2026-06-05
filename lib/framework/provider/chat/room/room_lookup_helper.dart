import '../../../domain/ChatRoomVO.dart';

/// 房间安全查找工具，统一“查询不抛异常”的约束。
class RoomLookupHelper {
  RoomLookupHelper._();

  static ChatRoomVO? findByRoomId(
    List<ChatRoomVO>? rooms,
    String? roomId,
  ) {
    if (rooms == null || rooms.isEmpty || roomId == null || roomId.isEmpty) {
      return null;
    }

    for (final room in rooms) {
      if (room.roomId == roomId) {
        return room;
      }
    }
    return null;
  }

  static ChatRoomVO? findPrivateByPeerId(
    List<ChatRoomVO>? rooms,
    int targetUserId,
  ) {
    if (rooms == null || rooms.isEmpty) {
      return null;
    }

    for (final room in rooms) {
      if (room.roomType == 0 && room.peerId == targetUserId) {
        return room;
      }
    }
    return null;
  }
}
