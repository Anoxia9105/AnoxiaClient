import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

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
      return const Center(child: Text("请选择一个联系人"));
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
        data: (detail) => _buildDetailContent(context, detail, isOnline),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("加载失败: $err")),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    ChatContactDetailVO detail,
    bool isOnline,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

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
          _buildInfoTile(context, "状态", isOnline ? "在线" : "离线"),
          _buildInfoTile(context, "备注名", detail.remark ?? "无备注"),
          _buildInfoTile(context, "用户账号", detail.userName ?? ""),
          _buildInfoTile(context, "性别", detail.genderText),
          _buildInfoTile(context, "电话", detail.phoneNumber ?? '没有电话'),
          _buildInfoTile(context, "成为好友", detail.formattedDate),

          // 格式化后的时间
          const SizedBox(height: 40),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 这里处理发消息逻辑
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text("发消息"),
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
