import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/chat_room_vo.dart';
import '../../../domain/official_room_config.dart';

part 'official_room_provider.g.dart';

/// 构建纯前端虚拟官方房间。
///
/// 该房间不来自服务端，仅用于展示功能引导 / 帮助，不支持聊天、通话与成员管理。
@Riverpod(keepAlive: true)
ChatRoomVO officialRoom(Ref ref) {
  return ChatRoomVO(
    roomId: OfficialRoomConfig.virtualRoomId,
    roomName: 'official_room_name'.tr(),
    roomAvatar: '',
    roomDescription: 'official_room_welcome_desc'.tr(),
    roomStatus: 0,
    roomType: RoomType.official.index,
    unreadCount: 0,
  );
}
