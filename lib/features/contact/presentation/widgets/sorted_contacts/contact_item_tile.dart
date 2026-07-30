import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 联系人项组件
///
/// 显示单个联系人的头像、昵称和在线状态
class ContactItemTile extends ConsumerWidget {
  /// 联系人对象
  final ChatContactVO contact;

  /// 点击回调（可选）
  final VoidCallback? onTap;

  const ContactItemTile({super.key, required this.contact, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        minLeadingWidth: 40,
        horizontalTitleGap: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        selectedColor: colorScheme.primary,
        leading: AvatarWidget(
          size: 34,
          url: contact.avatar,
          name: contact.nickName,
          status: contact.onlineStatus ?? false
              ? AvatarStatus.online
              : AvatarStatus.offline,
        ),
        title: Text(
          contact.remark ?? contact.nickName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          ref.read(contactSelectionProvider.notifier).selectContact(contact);
          onTap?.call();
        },
      ),
    );
  }
}
