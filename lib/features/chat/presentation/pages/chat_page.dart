import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/search_context_page.dart';
import 'package:anoxia/common/widgets/Welcome.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isRealMobile()) {
      return const ChatRoomList();
    }

    final currentRoom = ref.watch(activeRoomProvider);

    return Row(
      children: [
        SizedBox(width: 90.w, child: const ChatRoomList()),
        const VerticalDivider(),
        Expanded(
          child: currentRoom == null
              ? const Center(child: Welcome())
              : Row(
                  children: [
                    const Expanded(child: ChatRoomDetail()),
                    const VerticalDivider(),
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
