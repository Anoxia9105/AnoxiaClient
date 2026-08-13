import 'chat_room_vo.dart';

/// 官方虚拟房间配置
///
/// 官方欢迎会话已改为纯前端虚拟房间：服务端不再在注册时创建真实聊天房间，
/// 客户端在房间列表中注入一个虚拟房间用于展示功能引导 / 帮助。
class OfficialRoomConfig {
  OfficialRoomConfig._();

  /// 官方账号固定用户名（由已废弃的 2026-08-08-official-account.sql 插入）。
  static const String accountUserName = 'anoxia_official';

  /// 旧版真实官方房间的展示名，用于识别并清理已存在的真实房间。
  static const String legacyRoomName = 'Anoxia 官方';

  /// 虚拟官方房间 ID（非服务端房间，仅前端存在）。
  static const String virtualRoomId = 'official_welcome';

  /// 判断房间是否为（旧版）真实官方房间。
  static bool isLegacyOfficialRoom(ChatRoomVO room) {
    return room.roomName == legacyRoomName || room.roomId == virtualRoomId;
  }
}
