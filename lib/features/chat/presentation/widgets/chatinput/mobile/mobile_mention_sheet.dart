import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 手机专用提及选择器：搜索、全宽列表与独立滚动，不沿用桌面气泡尺寸。
class MobileMentionSheet extends StatefulWidget {
  const MobileMentionSheet({
    super.key,
    required this.users,
    required this.onSelected,
  });
  final List<MentionUser> users;
  final ValueChanged<MentionUser> onSelected;

  @override
  State<MobileMentionSheet> createState() => _MobileMentionSheetState();
}

class _MobileMentionSheetState extends State<MobileMentionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final users = MentionUser.filterUsers(widget.users, _query.trim());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAt,
                      color: colors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'mention_select_user'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'cancel'.tr(),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: colors.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'appbar_search_hint'.tr(),
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 20,
                    ),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _query.trim().isEmpty
                                ? 'mention_no_users'.tr()
                                : 'mention_user_not_found'.tr(
                                    args: [_query.trim()],
                                  ),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            minTileHeight: 64,
                            leading: user.isAll
                                ? CircleAvatar(
                                    backgroundColor: colors.primaryContainer,
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedUserGroup,
                                      color: colors.onPrimaryContainer,
                                      size: 22,
                                    ),
                                  )
                                : AvatarWidget(
                                    url: user.avatar,
                                    name: user.name,
                                    size: 40,
                                  ),
                            title: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: colors.onSurfaceVariant,
                              size: 18,
                            ),
                            onTap: () => widget.onSelected(user),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
