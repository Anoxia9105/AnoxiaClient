import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class CallInviteMembersButton extends ConsumerWidget {
  const CallInviteMembersButton({super.key, required this.state});

  final RoomState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: '邀请成员',
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showMembers(context, ref),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: HugeIcon(icon: HugeIcons.strokeRoundedAddTeam, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMembers(BuildContext context, WidgetRef ref) async {
    final roomId = state.room.name ?? '';
    if (roomId.isEmpty) return;
    await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
    if (!context.mounted) return;

    final currentUserId = ref.read(authControllerProvider).value?.userId;
    final joinedIds = <int>{
      if (state.room.localParticipant != null)
        int.tryParse(state.room.localParticipant!.identity) ?? -1,
      ...state.remoteParticipants.map((p) => int.tryParse(p.identity) ?? -1),
    };
    final members = ref
        .read(roomMembersProvider(roomId))
        .where(
          (m) =>
              m.userId != null &&
              m.userId != currentUserId &&
              !joinedIds.contains(m.userId),
        )
        .toList();
    final selected = <int>{};

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('邀请成员加入通话'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: members.isEmpty
                ? const Center(child: Text('所有成员都已加入'))
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final id = member.userId!;
                      return CheckboxListTile(
                        value: selected.contains(id),
                        onChanged: (checked) => setDialogState(() {
                          checked == true
                              ? selected.add(id)
                              : selected.remove(id);
                        }),
                        secondary: AvatarWidget(
                          size: 38,
                          url: member.avatar ?? '',
                          name: member.nickName ?? '',
                        ),
                        title: Text(member.nickName ?? '成员$id'),
                        subtitle: Text(
                          member.onlineStatus == true ? '在线' : '离线',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      final media = state.cameraEnabled
                          ? CallInitialMedia.video
                          : CallInitialMedia.audio;
                      if (DeviceUtil.isRealDesktop()) {
                        Channel.callChannel
                            .invokeMethod('invite_call_members', {
                              'roomId': roomId,
                              'title': state.room.name ?? '',
                              'initialMedia': media.value,
                              'userIds': selected.toList(),
                            });
                      } else {
                        ref
                            .read(callInvitationControllerProvider.notifier)
                            .inviteMembers(
                              ChatRoomVO(
                                roomId: roomId,
                                roomName: state.room.name,
                                roomType: 1,
                              ),
                              selected,
                              initialMedia: media,
                            );
                      }
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已邀请 ${selected.length} 位成员')),
                      );
                    },
              child: const Text('发送邀请'),
            ),
          ],
        ),
      ),
    );
  }
}
