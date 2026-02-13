import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
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
    final currentMembers = ref.watch(
      roomMemberServiceProvider.select(
        (state) => state[widget.roomId] ?? [],
      ),
    );

    // 获取当前群聊成员的用户ID列表
    final currentMemberIds = currentMembers.map((m) => m.userId).toSet();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
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
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '添加成员',
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
                        children:
                        [
                          Text(
                            widget.roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '群聊',
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
                      .where((contact) => 
                          contact.contactId != null && 
                          !currentMemberIds.contains(contact.contactId))
                      .toList();
                  
                  if (contacts.isEmpty) {
                    return Center(
                      child: Text('没有可添加的联系人'),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final isSelected = selectedContactIds.contains(contact.contactId);

                      return ListTile(
                        leading: AvatarWidget(
                          url: contact.avatar,
                          name: contact.nickName,
                          size: 40,
                          status: contact.onlineStatus ?? false
                              ? AvatarStatus.online
                              : AvatarStatus.offline,
                        ),
                        title: Text(contact.nickName ?? '未知用户'),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Center(
                  child: Text('加载联系人失败'),
                ),
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
                      child: Text('取消'.tr()),
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
                                    color: Theme.of(context).colorScheme.surface,
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
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('正在添加成员...'),
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

                              // 关闭对话框
                              Navigator.pop(context);

                              // 显示结果
                              Toast.showWidget(
                                context,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
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
                                  child: Text(
                                    success
                                        ? '添加成员成功'
                                        : '添加成员失败',
                                    style: TextStyle(
                                      color: success
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        '添加 (${selectedContactIds.length})',
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
