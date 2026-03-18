import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/pages/chat/component/ChatRoomDetail.dart';
import 'package:anoxia/pages/chat/component/ChatRoomList.dart';
import 'package:anoxia/pages/chat/component/widget/SearchContextPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/Welcome.dart';
import '../../framework/logs/talker.dart';
import '../../framework/provider/chat/room/room_list_service.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isRealMobile()) {
      return ChatRoomList();
    }

    final activeId = ref.watch(activeRoomIdProvider);

    final currentRoom = ref
        .read(roomListServiceProvider)
        .value
        ?.firstWhere((r) => r.roomId == activeId, orElse: () => ChatRoomVO());
    final roomName = currentRoom?.roomName ?? 'appbar_conversation_detail'.tr();

    return Row(
      children: [
        SizedBox(width: 90.w, child: ChatRoomList()),
        VerticalDivider(),
        Expanded(
          child: activeId == null
              ? Center(child: Welcome())
              : Row(
                  children: [
                    Expanded(child: ChatRoomDetail()),
                    VerticalDivider(),
                    SizedBox(
                      width: 100.w,
                      child: SearchContextPage(
                        roomId: activeId,
                        roomName: roomName,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
