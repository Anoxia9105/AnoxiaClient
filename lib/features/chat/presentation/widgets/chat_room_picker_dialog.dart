import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<ChatRoomVO?> showChatRoomPicker(BuildContext context) =>
    showDialog<ChatRoomVO>(
      context: context,
      builder: (_) => const _ChatRoomPickerDialog(),
    );

class _ChatRoomPickerDialog extends ConsumerWidget {
  const _ChatRoomPickerDialog();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms =
        ref.watch(roomListServiceProvider).value ?? const <ChatRoomVO>[];
    final available = rooms
        .where(
          (r) =>
              r.roomId?.isNotEmpty == true &&
              r.roomType != RoomType.aiChat.index &&
              (r.roomStatus ?? 0) < 2,
        )
        .toList();
    return AlertDialog(
      title: Text('share_select_chat'.tr()),
      content: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 80).clamp(260.0, 420.0),
        height: 420,
        child: available.isEmpty
            ? Center(child: Text('contact_recommend_no_chat'.tr()))
            : ListView.builder(
                itemCount: available.length,
                itemBuilder: (context, i) {
                  final room = available[i];
                  return ListTile(
                    leading: AvatarWidget(
                      url: room.roomAvatar,
                      name: room.roomName,
                      size: 40,
                    ),
                    title: Text(room.roomName ?? ''),
                    onTap: () => Navigator.pop(context, room),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('dialog_cancel'.tr()),
        ),
      ],
    );
  }
}
