import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

class AddMemberDialogWidget extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const AddMemberDialogWidget({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  @override
  ConsumerState createState() => _AddMemberDialogWidgetState();
}

class _AddMemberDialogWidgetState extends ConsumerState<AddMemberDialogWidget> {
  final Set<int> selectedContactIds = {};

  @override
  Widget build(BuildContext context) {
    final contactListAsync = ref.watch(contactListServiceProvider);
    final members = ref.watch(
      roomMemberServiceProvider.select(
        (s) => s[widget.roomId]?.values.toList() ?? const <ChatRoomMemberVO>[],
      ),
    );

    final currentMemberIds = members.map((e) => e.userId).toSet();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'member_add_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 为了平衡布局
                ],
              ),
            ),

            // 群聊信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUserGroup02,
                          color: Colors.white,
                          size: 20,
                        ),
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
                          ),
                          Text(
                            'member_group_chat'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 联系人列表
            Expanded(
              child: contactListAsync.when(
                data: (contactMap) {
                  // 过滤掉已经是群聊成员的联系人
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
                      final isSelected = selectedContactIds.contains(
                        contact.contactId,
                      );

                      return ListTile(
                        leading: AvatarWidget(
                          url: contact.avatar,
                          name: contact.nickName,
                          size: 40,
                          status: contact.onlineStatus ?? false
                              ? AvatarStatus.online
                              : AvatarStatus.offline,
                        ),
                        title: Text(
                          contact.nickName ?? 'chat_unknown_user'.tr(),
                        ),
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
                            if (selectedContactIds.contains(
                              contact.contactId,
                            )) {
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
                error: (err, stack) =>
                    Center(child: Text('member_load_failed'.tr())),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
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
                              // 显示加载状态
                              Toast.showWidget(
                                context,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        spreadRadius: 0,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('member_adding'.tr()),
                                    ],
                                  ),
                                ),
                              );

                              // 调用添加成员的API
                              final success = await ref
                                  .read(roomMemberServiceProvider.notifier)
                                  .addMembers(
                                    widget.roomId,
                                    selectedContactIds.toList(),
                                  );

                              if (!context.mounted) return;

                              // 关闭对话框
                              Navigator.pop(context);

                              // 显示结果
                              Toast.showToast(
                                success
                                    ? 'member_add_success'.tr()
                                    : 'member_add_failed'.tr(),
                                type: success
                                    ? ToastType.success
                                    : ToastType.error,
                              );
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
          ],
        ),
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
