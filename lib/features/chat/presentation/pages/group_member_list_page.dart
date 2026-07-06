import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupMemberListPage extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const GroupMemberListPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<GroupMemberListPage> createState() =>
      _GroupMemberListPageState();
}

class _GroupMemberListPageState extends ConsumerState<GroupMemberListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomMemberServiceProvider.notifier).syncMembers(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(roomMembersProvider(widget.roomId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${'appbar_member_list'.tr()} (${members.length})',
        ),
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: members.isEmpty
          ? Center(child: Text('member_no_contacts'.tr()))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final member = members[index];
                final isAdmin = member.roleId == 0;

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLowest,
                  leading: AvatarWidget(
                    url: member.avatar,
                    name: member.nickName,
                    size: 40,
                    status: (member.onlineStatus ?? false)
                        ? AvatarStatus.online
                        : AvatarStatus.offline,
                  ),
                  title: Text(
                    member.nickName ?? 'chat_unknown_user'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    member.userId != null
                        ? 'ID: ${member.userId}'
                        : 'chat_unknown_user'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isAdmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'chat_admin_role'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => _openContactDetailByMember(context, member),
                );
              },
            ),
    );
  }

  Future<void> _openContactDetailByMember(
    BuildContext context,
    ChatRoomMemberVO member,
  ) async {
    var contactMap = ref.read(contactListServiceProvider).value;

    if (contactMap == null || !contactMap.containsKey(member.userId)) {
      await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
      contactMap = ref.read(contactListServiceProvider).value;
    }

    final contact = contactMap?[member.userId];
    if (contact == null) {
      return;
    }

    ref.read(contactSelectionProvider.notifier).selectContact(contact);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContactDetail()),
    );
  }
}
