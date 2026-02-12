import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../framework/domain/ChatContactDetailVO.dart';

class ContactDetail extends ConsumerWidget {
  const ContactDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取当前选中的联系人基础信息
    final selection = ref.watch(contactSelectionProvider);
    final contact = selection.selectedContact;

    // 如果没选中，或者当前不是详情视图，显示空状态
    if (selection.viewType != ContactViewType.contactDetail ||
        contact == null) {
      return Center(child: Text('contact_select_contact'.tr()));
    }

    // 只要 SystemEventService 更新了 ContactListService，这里就会自动刷新
    final isOnline = ref.watch(
      contactListServiceProvider.select(
        (asyncMap) => asyncMap.value?[contact.contactId]?.onlineStatus ?? false,
      ),
    );
    // 2. 根据 ID 获取后端详细数据
    final detailAsync = ref.watch(
      contactDetailDataProvider(contact.contactId!),
    );

    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => _buildDetailContent(context, detail, isOnline, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('contact_load_failed'.tr() + ': $err')),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    ChatContactDetailVO detail,
    bool isOnline,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // 监听加载状态
    final isCreating = ref.watch(contactChatLoadingProvider);
    return SingleChildScrollView(
      child: Column(
        children: [
          // 顶部头像和基本信息区域
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                AvatarWidget(
                  url: detail.avatar,
                  name: detail.nickName,
                  size: 100,
                  borderRadius: 12,
                ),
                const SizedBox(height: 16),
                Text(
                  detail.nickName ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   "账号: ${detail.userName ?? '未知'}",
                //   style: TextStyle(color: colorScheme.outline),
                // ),
              ],
            ),
          ),

          const Divider(),

          // Text("${detail.phoneNumber?.isEmpty}--${detail.phoneNumber ?? '----'}"),
          // 详细资料项列表
          _buildInfoTile(context, 'contact_status'.tr(), isOnline ? 'contact_online'.tr() : 'contact_offline'.tr()),
          _buildInfoTile(context, 'contact_remark'.tr(), detail.remark ?? 'contact_no_remark'.tr()),
          _buildInfoTile(context, 'contact_username'.tr(), detail.userName ?? ""),
          _buildInfoTile(context, 'contact_gender'.tr(), _getTranslatedGender(detail.sex, context)),
          _buildInfoTile(context, 'contact_phone'.tr(), detail.phoneNumber ?? 'contact_no_phone'.tr()),
          _buildInfoTile(context, 'contact_became_friends'.tr(), detail.formattedDate),

          // 格式化后的时间
          const SizedBox(height: 40),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isCreating
                        ? null
                        : () async {
                            final targetId = detail.userId; // 对方的用户ID
                            if (targetId == null) return;

                            //开启加载
                            ref
                                .read(contactChatLoadingProvider.notifier)
                                .set(true);

                            try {
                              final roomId = await ref
                                  .read(roomListServiceProvider.notifier)
                                  .getOrCreateRoom(detail.userId!);

                              if (roomId != null) {
                                ref
                                    .read(activeRoomIdProvider.notifier)
                                    .setActive(roomId);
                                ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(0);
                              }
                            } finally {
                              // 关闭加载
                              ref
                                  .read(contactChatLoadingProvider.notifier)
                                  .set(false);
                            }
                          },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: isCreating
                        ? CircularProgressIndicator()
                        : Text('chat_send_message'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTranslatedGender(String? sex, BuildContext context) {
    switch (sex) {
      case '0': return 'contact_male'.tr();
      case '1': return 'contact_female'.tr();
      default: return 'contact_unknown_gender'.tr();
    }
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
