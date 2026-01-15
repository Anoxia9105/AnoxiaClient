import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:anoxia/pages/chat/component/ChatRoomDetail.dart';
import 'package:anoxia/pages/chat/component/ChatRoomList.dart';

import '../../common/widgets/Welcome.dart';
import '../../framework/provider/theme/theme_controller.dart';
import '../../framework/services/room_list_service.dart';
import '../../framework/services/room_message_service.dart';
import '../../framework/theme/AppTheme.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final allMessages = ref.watch(chatMessagesProvider);
    final count = ref.watch(chatMessagesProvider.notifier).totalMessageCount;
    final activeId = ref.watch(activeRoomIdProvider);
    return Row(
      children: [
        SizedBox(width: 80.w, child: ChatRoomList()),
        Expanded(
          child: activeId == null
              ? Center(child: Welcome())
              : ChatRoomDetail(),
        ),
      ],
    );

    return Column(
      children: [
        FilledButton(
          onPressed: () {
            ErrorRoute().go(context);
          },
          child: Text("data"),
        ),
        DropdownButton<int>(
          value: ref.watch(themeIndexProvider),
          items: List.generate(AppTheme.themes.length, (i) {
            return DropdownMenuItem(
              value: i,
              child: Text(AppTheme.themes[i].localizedName),
            );
          }),
          onChanged: (i) {
            if (i != null) {
              ref.read(themeIndexProvider.notifier).setTheme(i);
            }
          },
        ),
        Text("$count"),
        Expanded(child: ChatRoomDetail()),
      ],
    );
  }
}
