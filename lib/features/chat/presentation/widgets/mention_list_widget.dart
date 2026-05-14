import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

/// 提及用户数据模型
class MentionUser {
  final int id;
  final String name;
  final String? avatar;

  MentionUser({required this.id, required this.name, this.avatar});
}

/// @提及列表组件
class MentionListWidget extends ConsumerWidget {
  final Function(MentionUser) onUserSelected;
  final List<MentionUser> users; // 可提及的用户列表

  const MentionListWidget({
    required this.onUserSelected,
    required this.users,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // 从 provider 实时获取搜索文本
    final searchText = ref.watch(
      mentionStateProvider.select((state) => state.searchText),
    );

    // 根据搜索文本过滤用户
    final filteredUsers = users.where((user) {
      if (searchText.isEmpty) return true;
      return user.name.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    if (filteredUsers.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minWidth: 200),
          child: Text(
            searchText.isEmpty
                ? 'mention_no_users'.tr()
                : 'mention_user_not_found'.tr(args: [searchText]),
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 200,
          minWidth: 200,
          maxWidth: 300,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return InkWell(
              onTap: () => onUserSelected(user),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: user.avatar != null
                          ? ClipOval(
                              child: Image.network(
                                user.avatar!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialAvatar(user.name, colorScheme),
                              ),
                            )
                          : _buildInitialAvatar(user.name, colorScheme),
                    ),
                    const SizedBox(width: 12),
                    // 用户名
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name, ColorScheme colorScheme) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 14,
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
