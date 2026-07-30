import 'package:anoxia/common/utils/device_util.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_detail_settings_body.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// !!!!  不适用于桌面端 !!!!
/// 聊天房间详情设置页（移动端整页版本）
class ChatRoomDetailSettingsPage extends StatelessWidget {
  final String roomId;

  const ChatRoomDetailSettingsPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text('chat_conversation_detail'.tr()),
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: RoomDetailSettingsBody(roomId: roomId),
    );
  }
}
