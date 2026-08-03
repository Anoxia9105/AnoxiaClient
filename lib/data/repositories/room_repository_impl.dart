import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/room_repository.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 房间仓库实现
///
/// 通过远程数据源（HTTP API）提供房间相关操作。
/// 实现 [RoomRepository] 抽象接口，供 UI 层 Provider 使用。
class RoomRepositoryImpl implements RoomRepository {
  @override
  Future<ChatRoomVO?> createPrivateRoom(int targetUserId) async {
    final res = await DioClient().get(
      API.chatCreatePrivate,
      queryParameters: {'targetId': targetUserId},
    );

    final data = res.data['data'];
    if (data == null) return null;
    return ChatRoomVO.fromJson(data);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final res = await DioClient().get(
      API.chatRoomLeave,
      queryParameters: {'roomId': roomId},
    );
    if (res.data['code'] != 200) {
      throw Exception('delete conversation failed');
    }
  }

  @override
  Future<void> disbandRoom(String roomId) async {
    final res = await DioClient().get(
      API.chatRoomDisband,
      queryParameters: {'roomId': roomId},
    );
    log.debug('[Room] disbandRoom response: $res');
  }

  @override
  Future<bool> muteRoom(String roomId, bool isMute) async {
    try {
      final res = await DioClient().get(
        API.chatRoomMute,
        queryParameters: {'roomId': roomId, 'isMute': isMute},
      );
      return res.data['code'] == 200;
    } catch (e, st) {
      log.error('[Room] muteRoom 失败', e, st);
      return false;
    }
  }

  @override
  Future<bool> updateGroupName(String roomId, String roomName) async {
    final safeName = roomName.trim();
    if (roomId.isEmpty || safeName.isEmpty) {
      return false;
    }

    try {
      final res = await DioClient().post(
        API.chatRoomUpdateName,
        data: {'roomId': roomId, 'roomName': safeName},
      );
      return res.data['code'] == 200;
    } catch (e, st) {
      log.error('[Room] 修改群聊名称失败', e, st);
      return false;
    }
  }

  @override
  Future<bool> updateGroupAnnouncement(
    String roomId,
    String roomAnnouncement,
  ) async {
    final safeAnnouncement = roomAnnouncement.trim();
    if (roomId.isEmpty) {
      return false;
    }

    try {
      final res = await DioClient().post(
        API.chatRoomUpdateAnnouncement,
        data: {'roomId': roomId, 'roomAnnouncement': safeAnnouncement},
      );
      return res.data['code'] == 200;
    } catch (e, st) {
      log.error('[Room] 修改群公告失败', e, st);
      return false;
    }
  }
}
