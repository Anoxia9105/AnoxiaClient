import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 联系人 / 收藏选择页；只返回选择结果，发送由聊天入口负责。
class ChatContentPicker extends ConsumerStatefulWidget {
  final bool favorites;
  const ChatContentPicker({super.key, required this.favorites});
  @override
  ConsumerState<ChatContentPicker> createState() => _ChatContentPickerState();
}

class _ChatContentPickerState extends ConsumerState<ChatContentPicker> {
  String _query = '';
  bool _confirming = false;

  Future<void> _select(Object item, String title) async {
    if (_confirming) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('chat_share_confirm'.tr()),
        content: Text(title, maxLines: 6, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('chat_share_send'.tr()),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed == true && mounted) Navigator.pop(context, item);
  }

  void _retry() {
    if (widget.favorites) {
      ref.invalidate(chatFavoriteListProvider);
    } else {
      ref.invalidate(contactListServiceProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Object>> items = widget.favorites
        ? ref
              .watch(chatFavoriteListProvider)
              .whenData((items) => items.cast<Object>())
        : ref
              .watch(contactListServiceProvider)
              .whenData(
                (items) => items.values
                    .where((c) => c.contactId != null)
                    .cast<Object>()
                    .toList(),
              );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          (widget.favorites ? 'chat_share_favorite' : 'chat_share_contact')
              .tr(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'chat_share_search'.tr(),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text('chat_share_retry'.tr()),
                  ),
                ),
                data: (all) {
                  String title(Object item) => switch (item) {
                    ChatFavorite f => f.summary,
                    ChatContactVO c =>
                      c.remark?.trim().isNotEmpty == true
                          ? c.remark!
                          : c.nickName ?? c.contactId.toString(),
                    _ => '',
                  };
                  final filtered = all
                      .where(
                        (item) => title(item).toLowerCase().contains(_query),
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text('chat_share_empty'.tr()));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      final label = title(item);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: item is ChatContactVO
                            ? AvatarWidget(
                                url: item.avatar,
                                name: label,
                                size: 48,
                              )
                            : CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: const Icon(
                                  Icons.bookmark_outline_rounded,
                                ),
                              ),
                        title: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: item is ChatFavorite
                            ? Text(
                                item.senderDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _select(item, label),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
