import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推荐联系人给好友时选择聊天室的对话框
class ContactRecommendDialog extends ConsumerWidget {
  const ContactRecommendDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomListServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = (screenSize.width - 80).clamp(260.0, 420.0);
    final dialogHeight = (screenSize.height * 0.62).clamp(280.0, 440.0);

    return AlertDialog(
      title: Text('contact_recommend_select_chat'.tr()),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: roomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton.icon(
              onPressed: () => ref
                  .read(roomListServiceProvider.notifier)
                  .refresh(silent: false),
              icon: const Icon(Icons.refresh),
              label: Text('contact_recommend_load_failed'.tr()),
            ),
          ),
          data: (allRooms) {
            final rooms = allRooms
                .where(
                  (room) =>
                      room.roomId?.isNotEmpty == true &&
                      room.roomType != RoomType.aiChat.index &&
                      (room.roomStatus == null || room.roomStatus == 0),
                )
                .toList();
            if (rooms.isEmpty) {
              return Center(child: Text('contact_recommend_no_chat'.tr()));
            }
            return ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  leading: AvatarWidget(
                    url: room.roomAvatar,
                    name: room.roomName,
                    size: 42,
                  ),
                  title: Text(
                    room.roomName?.trim().isNotEmpty == true
                        ? room.roomName!
                        : 'contact_recommend_unnamed_chat'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    room.roomType == RoomType.groupChat.index
                        ? 'contact_recommend_group_chat'.tr()
                        : 'contact_recommend_single_chat'.tr(),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  onTap: () => Navigator.pop(context, room),
                );
              },
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
