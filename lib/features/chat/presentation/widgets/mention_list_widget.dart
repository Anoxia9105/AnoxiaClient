import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 提及用户数据模型
class MentionUser {
  final int id;
  final String name;
  final String? avatar;

  /// 是否为「@所有人」占位项（仅群聊展示，不提醒真实用户）
  final bool isAll;

  MentionUser({
    required this.id,
    required this.name,
    this.avatar,
    this.isAll = false,
  });

  /// 构造「@所有人」占位项
  factory MentionUser.atAll() => MentionUser(
    id: kMentionAllUserId,
    name: 'mention_all'.tr(),
    isAll: true,
  );

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

  /// 解析 mention embed 数据并返回展示名称。
  ///
  /// 「@所有人」占位项（userId == [kMentionAllUserId]）始终返回
  /// 当前语言环境的本地化名称，不受发送者语言影响。
  static String? displayName(dynamic rawData) {
    try {
      final dynamic data = rawData is String ? jsonDecode(rawData) : rawData;
      if (data is Map) {
        if (data['userId'] == kMentionAllUserId) return 'mention_all'.tr();
        final userName = data['userName']?.toString().trim();
        if (userName != null && userName.isNotEmpty) return userName;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

/// @提及列表组件
class MentionListWidget extends ConsumerStatefulWidget {
  final Function(MentionUser) onUserSelected;
  final List<MentionUser> users; // 可提及的用户列表

  const MentionListWidget({
    required this.onUserSelected,
    required this.users,
    super.key,
  });

  @override
  ConsumerState<MentionListWidget> createState() => _MentionListWidgetState();
}

class _MentionListWidgetState extends ConsumerState<MentionListWidget> {
  /// 列表行高固定，键盘上下键导航时按行距精确滚动（气泡跟随选中项跳动）
  static const double _itemExtent = 48;

  /// ListView 的垂直内边距（与 build 中的 padding 保持一致）
  static const double _listPadding = 4;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 键盘选中项变化时，将气泡列表滚动到选中项所在位置。
  ///
  /// ListView.builder 懒构建，屏幕外的选中项不会触发 build，
  /// 不能再依赖项内的 Scrollable.ensureVisible，改为行距换算后主动滚动。
  /// 选中项已在可视区域内时不滚动，避免到达底部后多滚动一次的跳动。
  void _scrollToSelected(int index, int itemCount) {
    if (itemCount <= 0 || index < 0 || index >= itemCount) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    final itemTop = _listPadding + index * _itemExtent;
    final itemBottom = itemTop + _itemExtent;
    final viewportStart = position.pixels;
    final viewportEnd = viewportStart + position.viewportDimension;

    // 选中项完全可见：不滚动
    if (itemTop >= viewportStart && itemBottom <= viewportEnd) return;

    // 选中项在可视区上方：滚动使其顶部对齐可视区顶部
    final double target;
    if (itemTop < viewportStart) {
      target = itemTop.clamp(0.0, position.maxScrollExtent).toDouble();
    } else {
      // 选中项在可视区下方：滚动使其底部对齐可视区底部
      target = (itemBottom - position.viewportDimension)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble();
    }

    if ((target - position.pixels).abs() < 1) return;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final filteredUsers = MentionUser.filterUsers(widget.users, searchText);

    // 键盘选中项变化后滚动气泡列表，让选中项始终可见
    if (isKeyboardNavActive && filteredUsers.isNotEmpty) {
      final selectedIndex = mentionState.selectedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToSelected(selectedIndex, filteredUsers.length);
      });
    }

    if (filteredUsers.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(RadiusToken.md),
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
      borderRadius: BorderRadius.circular(RadiusToken.md),
      color: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 200,
          minWidth: 200,
          maxWidth: 300,
        ),
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          itemExtent: _itemExtent,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final isSelected =
                isKeyboardNavActive && index == mentionState.selectedIndex;

            return InkWell(
              onTap: () => widget.onUserSelected(user),
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
                    // 头像（@所有人 使用群组图标，其余与聊天列表头像保持一致）
                    if (user.isAll)
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUserGroup,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    else
                      AvatarWidget(url: user.avatar, name: user.name, size: 32),
                    const SizedBox(width: 12),
                    // 用户名
                    Expanded(
                      child: Text(
                        user.name,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
