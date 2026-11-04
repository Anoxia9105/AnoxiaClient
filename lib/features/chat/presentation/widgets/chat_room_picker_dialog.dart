// 聊天室选择对话框，用于在选择转发目标等场景中挑选聊天室。
//
// 展示当前可用的聊天室列表，用户点击选择后返回选中的聊天室。
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_write_access_provider.dart';
import 'package:anoxia/framework/provider/contact/private_contact_access.dart';
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
class _ChatRoomPickerDialog extends ConsumerStatefulWidget {
  const _ChatRoomPickerDialog();
  @override
  ConsumerState<_ChatRoomPickerDialog> createState() =>
      _ChatRoomPickerDialogState();
}

class _ChatRoomPickerDialogState extends ConsumerState<_ChatRoomPickerDialog> {
  String _query = '';
  bool _checking = false;

  Future<void> _select(ChatRoomVO room) async {
    if (_checking) return;
    final route = ModalRoute.of(context);
    final peerId = room.peerId;
    if (room.roomType == 0 && peerId != null) {
      setState(() => _checking = true);
      try {
        await ref.read(privateContactAccessProvider(peerId).future);
      } catch (_) {
        if (mounted && route?.isCurrent == true) {
          Toast.showToast(
            'chat_operation_retry_failed'.tr(),
            type: ToastType.error,
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _checking = false);
      }
    }
    if (!mounted || route?.isCurrent != true) return;
    if (!ref.read(roomWriteAccessProvider(room.roomId!))) {
      Toast.showToast(
        'chat_destination_read_only'.tr(),
        type: ToastType.warning,
      );
      return;
    }
    Navigator.pop(context, room);
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomListServiceProvider);
    final rooms = roomsState.value ?? const <ChatRoomVO>[];
    final available = rooms
        .where(
          (r) =>
              r.roomId?.isNotEmpty == true &&
              r.roomType != RoomType.aiChat.index &&
              !r.isOfficial &&
              r.roomStatus == 0 &&
              (r.roomName ?? '').toLowerCase().contains(_query),
        )
        .toList();
    return AlertDialog(
      title: Text('share_select_chat'.tr()),
      content: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 80).clamp(260.0, 420.0),
        height: (MediaQuery.sizeOf(context).height * 0.6).clamp(120.0, 420.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'chat_forward_search'.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: roomsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : roomsState.hasError
                  ? Center(
                      child: TextButton(
                        onPressed: () => ref
                            .read(roomListServiceProvider.notifier)
                            .refresh(),
                        child: Text('chat_forward_retry'.tr()),
                      ),
                    )
                  : available.isEmpty
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
                          onTap: _checking ? null : () => _select(room),
                        );
                      },
                    ),
            ),
          ],
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
