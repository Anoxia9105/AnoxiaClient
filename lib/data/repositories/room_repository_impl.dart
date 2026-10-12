import 'package:anoxia/common/constants/api.dart';
import 'package:cross_file/cross_file.dart';
import 'package:anoxia/domain/repositories/room_repository.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
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
    await DioClient().get(
      API.chatRoomDisband,
      queryParameters: {'roomId': roomId},
    );
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
      debugLog('[Room] muteRoom 失败', e, st);
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
      debugLog('[Room] 修改群聊名称失败', e, st);
      return false;
    }
  }

  @override
  Future<String?> uploadGroupAvatar(XFile file) async {
    final res = await DioClient().uploadFile(API.groupAvatarUpload, file: file);
    final body = res.data;
    return body is Map && body['code'] == 200 && body['data'] is String
        ? body['data'] as String
        : null;
  }

  @override
  Future<bool> updateGroupAvatar(String roomId, String avatarUrl) async {
    try {
      final res = await DioClient().post(
        API.chatRoomUpdateAvatar,
        data: {'roomId': roomId, 'avatarUrl': avatarUrl},
      );
      return res.data is Map && res.data['code'] == 200;
    } catch (e, st) {
      debugLog('[Room] 修改群头像失败', e, st);
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
      debugLog('[Room] 修改群公告失败', e, st);
      return false;
    }
  }
}
