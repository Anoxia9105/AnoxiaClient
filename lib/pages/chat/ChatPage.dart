import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/pages/chat/component/ChatRoomDetail.dart';
import 'package:anoxia/pages/chat/component/ChatRoomList.dart';
import 'package:anoxia/pages/chat/component/widget/SearchContextPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/Welcome.dart';
import '../../framework/provider/chat/room/room_list_service.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isRealMobile()) {
      return ChatRoomList();
    }

    final currentRoom = ref.watch(activeRoomProvider);

    return Row(
      children: [
        SizedBox(width: 90.w, child: ChatRoomList()),
        VerticalDivider(),
        Expanded(
          child: currentRoom == null
              ? Center(child: Welcome())
              : Row(
                  children: [
                    Expanded(child: ChatRoomDetail()),
                    VerticalDivider(),
                    if (currentRoom.isOpenSearch == true)
                      SizedBox(
                        width: 100.w,
                        child: SearchContextPage(
                          roomId: currentRoom.roomId!,
                          roomName:
                              currentRoom.roomName ??
                              'appbar_conversation_detail'.tr(),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
