import 'package:anoxia/common/widgets/avatar_widget.dart';
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

  /// 按搜索文本过滤可提及用户（键盘导航与列表展示共用同一过滤逻辑）
  static List<MentionUser> filterUsers(
    List<MentionUser> users,
    String searchText,
  ) {
    if (searchText.isEmpty) return users;
    final query = searchText.toLowerCase();
    return users
        .where((user) => user.name.toLowerCase().contains(query))
        .toList();
  }
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

    // 从 provider 实时获取搜索文本与键盘选中索引
    final mentionState = ref.watch(
      mentionStateProvider.select(
        (state) => (
          isShowing: state.isShowing,
          searchText: state.searchText,
          selectedIndex: state.selectedIndex,
        ),
      ),
    );
    final searchText = mentionState.searchText;
    // 仅当 @弹窗处于展示状态时（桌面端）才显示键盘选中高亮，
    // 移动端底部弹出的选择列表不参与键盘导航
    final isKeyboardNavActive = mentionState.isShowing;

    // 根据搜索文本过滤用户
    final filteredUsers = MentionUser.filterUsers(users, searchText);

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
            final isSelected =
                isKeyboardNavActive && index == mentionState.selectedIndex;

            // 键盘选中项滚动到可视区域
            if (isSelected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 100),
                );
              });
            }

            return InkWell(
              onTap: () => onUserSelected(user),
              child: Container(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 头像（与聊天列表头像保持一致）
                    AvatarWidget(url: user.avatar, name: user.name, size: 32),
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
}
