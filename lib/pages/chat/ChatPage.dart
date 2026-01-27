import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/pages/chat/component/ChatRoomDetail.dart';
import 'package:anoxia/pages/chat/component/ChatRoomList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/Welcome.dart';
import '../../framework/services/room_list_service.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isRealMobile()) {
      return ChatRoomList();
    }

    final activeId = ref.watch(activeRoomIdProvider);
    return Row(
      children: [
        SizedBox(width: 90.w, child: ChatRoomList()),
        VerticalDivider(),
        Expanded(
          child: activeId == null ? Center(child: Welcome()) : ChatRoomDetail(),
        ),
      ],
    );
  }
}
