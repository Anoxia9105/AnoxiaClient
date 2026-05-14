import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/framework/domain/UserVO.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AddFriendSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  const AddFriendSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'add_friend_search_hint'.tr(),
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 14.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.outline,
                  size: 19,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.outline,
                          size: 18,
                        ),
                        onPressed: onClear,
                        splashRadius: 18,
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              onSubmitted: onSubmitted,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isSearching ? null : onSearch,
            style: FilledButton.styleFrom(
              minimumSize: const Size(42, 42),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class AddFriendSearchSkeleton extends StatelessWidget {
  const AddFriendSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 52, height: 52, circle: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 180, height: 11),
                    SizedBox(height: 7),
                    SkeletonLine(width: 140, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SkeletonBox(width: 62, height: 30, radius: 14),
            ],
          ),
        );
      },
    );
  }
}

class AddFriendUserCard extends StatelessWidget {
  final UserVO user;
  final bool isFriend;
  final VoidCallback onTapAdd;

  const AddFriendUserCard({
    super.key,
    required this.user,
    required this.isFriend,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isFriend ? null : onTapAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AvatarWidget(url: user.avatar, name: user.nickName, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'add_friend_username'.tr(args: [user.userName]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          fontSize: 12.5,
                        ),
                      ),
                      if ((user.phonenumber ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'add_friend_phone'.tr(args: [user.phonenumber!]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                isFriend
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'add_friend_already_friend'.tr(),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : FilledButton.tonal(
                        onPressed: onTapAdd,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(60, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'add_friend_add_btn'.tr(),
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddFriendEmptyState extends StatelessWidget {
  final bool hasKeyword;

  const AddFriendEmptyState({super.key, required this.hasKeyword});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (hasKeyword) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch02,
                size: 72,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'add_friend_not_found'.tr(),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'add_friend_try_other_keyword'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUserAdd02,
              size: 96,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'add_friend_search_to_add'.tr(),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'add_friend_input_hint'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
