import 'chat_room_vo.dart';

/// 官方虚拟房间配置
///
/// 官方欢迎会话已改为纯前端虚拟房间：服务端不再在注册时创建真实聊天房间，
/// 客户端在房间列表中注入一个虚拟房间用于展示功能引导 / 帮助。
class OfficialRoomConfig {
  OfficialRoomConfig._();

  /// 虚拟官方房间 ID（非服务端房间，仅前端存在）。
  static const String virtualRoomId = 'official_welcome';

  /// 判断服务端房间是否误用了前端保留的虚拟房间 ID。
  static bool usesReservedVirtualRoomId(ChatRoomVO room) {
    return room.roomId == virtualRoomId;
  }
}
