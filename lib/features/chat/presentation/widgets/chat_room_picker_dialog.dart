/// 聊天室选择对话框，用于在选择转发目标等场景中挑选聊天室。
///
/// 展示当前可用的聊天室列表，用户点击选择后返回选中的聊天室。
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 显示聊天室选择对话框。
///
/// 返回用户选择的 [ChatRoomVO]，如果用户取消则返回 null。
Future<ChatRoomVO?> showChatRoomPicker(BuildContext context) =>
    showDialog<ChatRoomVO>(
      context: context,
      builder: (_) => const _ChatRoomPickerDialog(),
    );

/// 聊天室选择对话框内部组件。
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