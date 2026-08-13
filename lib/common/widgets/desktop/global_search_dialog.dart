import 'package:anoxia/features/chat/presentation/formatters/message_preview_formatter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/provider/desktop/desktop_search_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局搜索对话框
///
/// 支持搜索会话和联系人
class GlobalSearchDialog extends ConsumerWidget {
  final TextEditingController _searchController = TextEditingController();

  GlobalSearchDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // 监听注解版 Provider 的状态
    final searchState = ref.watch(desktopSearchControllerProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 80),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                // 通过 notifier 更新状态
                onChanged: (v) => ref
                    .read(desktopSearchControllerProvider.notifier)
                    .updateQuery(v),
                decoration: InputDecoration(
                  hintText: '${'search'.tr()}（会话 / 联系人）',
                  prefixIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch02,
                    size: 16,
                  ),
                  suffixText: 'Ctrl+K',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: searchState.query.isEmpty
                  ? Center(
                      child: Text(
                        '输入关键词以搜索会话和联系人',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [
                        _ResultSectionTitle(title: 'global_search_section_conversations'.tr()),
                        if (searchState.rooms.isEmpty)
                          const _ResultEmpty(text: '未找到相关会话')
                        else
                          ...searchState.rooms.map(
                            (room) => _ResultTile(
                              icon: room.roomType == 1
                                  ? HugeIcons.strokeRoundedUserGroup02
                                  : HugeIcons.strokeRoundedUser,
                              title:
                                  room.roomName ??
                                  'chat_unknown_conversation'.tr(),
                              subtitle: MessagePreviewFormatter.format(
                                room.lastMessage,
                              ),
                              onTap: () {
                                ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(0);
                                if (room.roomId != null) {
                                  ref
                                      .read(activeRoomIdProvider.notifier)
                                      .setActive(room.roomId!);
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        _ResultSectionTitle(title: 'global_search_section_contacts'.tr()),
                        if (searchState.contacts.isEmpty)
                          const _ResultEmpty(text: '未找到相关联系人')
                        else
                          ...searchState.contacts.map(
                            (contact) => _ResultTile(
                              icon: HugeIcons.strokeRoundedBadge,
                              title: contact.remark?.isNotEmpty == true
                                  ? contact.remark!
                                  : (contact.nickName ??
                                        'chat_unknown_user'.tr()),
                              subtitle:
                                  'ID: ${contact.contactId ?? '-'} · ${contact.nickName ?? ''}',
                              onTap: () {
                                ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(1);
                                ref
                                    .read(contactSelectionProvider.notifier)
                                    .selectContact(contact);
                                Navigator.of(context).pop();
                              },
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

class _ResultSectionTitle extends StatelessWidget {
  final String title;

  const _ResultSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ResultEmpty extends StatelessWidget {
  final String text;

  const _ResultEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: HugeIcon(icon: icon, size: 18),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
