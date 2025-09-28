import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notepadclient/core/enums/LayoutType.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/features/chat/widgets/ChatDetail.dart';
import 'package:notepadclient/features/chat/widgets/ChatList.dart';
import 'package:notepadclient/features/setting/controller/SettingsController.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}


class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    final layoutType = context.select<SettingsController, LayoutType>(
          (s) => s.layoutType,
    );
    return Consumer<ChatController>(
      builder: (context, ChatController chat, child) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 100.w, height: double.infinity, child: ChatList()),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(2),
              child: layoutType == LayoutType.card
                  ? Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ChatDetail(),
                      ),
                    )
                  : ChatDetail(),
            ),
          ),
        ],
      ),
    );
  }
}
