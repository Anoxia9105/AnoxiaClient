import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 手机端添加群成员页面
class AddMemberPage extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const AddMemberPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends ConsumerState<AddMemberPage> {
  final Set<int> selectedContactIds = {};

  @override
  Widget build(BuildContext context) {
    final contactListAsync = ref.watch(contactListServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final members = ref.watch(
      roomMemberServiceProvider.select(
        (s) => s[widget.roomId]?.values.toList() ?? const <ChatRoomMemberVO>[],
      ),
    );
    final currentMemberIds = members.map((e) => e.userId).toSet();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('member_add_title'.tr()),
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(RadiusToken.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(RadiusToken.md),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserGroup,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'member_group_chat'.tr(),
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: contactListAsync.when(
              data: (contactMap) {
                final contacts = contactMap.values
                    .where(
                      (contact) =>
                          contact.contactId != null &&
                          !currentMemberIds.contains(contact.contactId),
                    )
                    .toList();

                if (contacts.isEmpty) {
                  return Center(child: Text('member_no_contacts'.tr()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected =
                        selectedContactIds.contains(contact.contactId);

                    return ListTile(
                      leading: AvatarWidget(
                        url: contact.avatar,
                        name: contact.nickName,
                        size: 40,
                        status: contact.onlineStatus ?? false
                            ? AvatarStatus.online
                            : AvatarStatus.offline,
                      ),
                      title: Text(contact.nickName ?? 'chat_unknown_user'.tr()),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              selectedContactIds.add(contact.contactId!);
                            } else {
                              selectedContactIds.remove(contact.contactId!);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (selectedContactIds.contains(contact.contactId)) {
                            selectedContactIds.remove(contact.contactId!);
                          } else {
                            selectedContactIds.add(contact.contactId!);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const _AddMemberListSkeleton(),
              error: (err, stack) => Center(
                child: Text('member_load_failed'.tr()),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('dialog_cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedContactIds.isEmpty
                          ? null
                          : () async {
                              final cancelLoading = BotToast.showLoading();
                              try {
                                final result = await ref
                                    .read(roomMemberServiceProvider.notifier)
                                    .addMembers(
                                      widget.roomId,
                                      selectedContactIds.toList(),
                                    );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                final success = result != null;
                                Toast.showToast(
                                  result == 'PENDING'
                                      ? 'member_add_pending'.tr()
                                      : success
                                          ? 'member_add_success'.tr()
                                          : 'member_add_failed'.tr(),
                                  type: success
                                      ? ToastType.success
                                      : ToastType.error,
                                );
                              } finally {
                                cancelLoading();
                              }
                            },
                      child: Text(
                        'member_add_count'.tr(
                          args: [selectedContactIds.length.toString()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberListSkeleton extends StatelessWidget {
  const _AddMemberListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final nameWidth = 95.0 + (index % 3) * 24;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const SkeletonBox(width: 40, height: 40, radius: 8),
          title: Align(
            alignment: Alignment.centerLeft,
            child: SkeletonLine(width: nameWidth, height: 13),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonLine(width: 76, height: 10),
            ),
          ),
          trailing: const SkeletonBox(width: 20, height: 20, radius: 6),
        );
      },
    );
  }
}
