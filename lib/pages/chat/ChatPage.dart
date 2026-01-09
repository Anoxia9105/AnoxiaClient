import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/provider/router/router.dart';
import 'package:notepadclient/pages/ErrorPage.dart';
import 'package:notepadclient/pages/chat/ChatRoomPage.dart';

import '../../framework/provider/theme/theme_controller.dart';
import '../../framework/services/room_message_service.dart';
import '../../framework/theme/AppTheme.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final allMessages = ref.watch(chatMessagesProvider);
    final count = ref.watch(chatMessagesProvider.notifier).totalMessageCount;
    return Column(
      children: [
        FilledButton(onPressed: (){
          ErrorRoute().go(context);
        }, child: Text("data")),
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
        Expanded(child: ChatRoomPage(roomId: "testroom1")),
      ],
    );
  }
}
