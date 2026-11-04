import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:cross_file/cross_file.dart';

/// 房间仓库抽象接口
///
/// 定义房间相关的数据操作契约：创建私聊房间、退出/解散房间、
/// 禁言、修改群名称和群公告。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class RoomRepository {
  /// 创建（或获取已有的）私聊房间
  ///
  /// [targetUserId] 目标用户 ID
  ///
  /// 返回创建/获取到的房间；失败或后端返回空数据时返回 null。
  Future<ChatRoomVO?> createPrivateRoom(int targetUserId);

  /// 退出聊天室
  ///
  /// [roomId] 目标房间 ID
  /// 操作失败时抛出异常。
  Future<void> leaveRoom(String roomId);

  Future<void> hideRoom(String roomId);

  /// 解散群聊
  ///
  /// [roomId] 目标房间 ID
  /// 操作失败时抛出异常。
  Future<void> disbandRoom(String roomId);

  /// 房间禁言/解除禁言
  ///
  /// [roomId] 房间ID
  /// [isMute] true=禁言，false=解除禁言
  ///
  /// 返回是否操作成功。
  Future<bool> muteRoom(String roomId, bool isMute);

  /// 修改群聊名称
  ///
  /// 返回是否操作成功。
  Future<bool> updateGroupName(String roomId, String roomName);

  /// 上传已裁剪的静态群头像。
  Future<String?> uploadGroupAvatar(XFile file);

  Future<bool> updateGroupAvatar(String roomId, String avatarUrl);

  /// 修改群公告
  ///
  /// 返回是否操作成功。
  Future<bool> updateGroupAnnouncement(String roomId, String roomAnnouncement);

  /// 更新成员级会话设置：置顶
  ///
  /// 服务端仅更新此字段；房间未找到或非成员时返回 false。
  Future<bool> setRoomPinned(String roomId, bool isPinned);

  /// 更新成员级会话设置：免打扰
  ///
  /// 服务端仅更新此字段；房间未找到或非成员时返回 false。
  Future<bool> setRoomDoNotDisturb(String roomId, bool isMuted);
}
