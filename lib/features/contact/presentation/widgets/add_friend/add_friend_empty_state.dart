import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

/// 添加好友空状态组件
///
/// 根据是否已输入关键词展示不同的引导/未找到提示
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch02,
                size: 48,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'add_friend_not_found'.tr(),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 17,
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
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
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
              size: 58,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'add_friend_search_to_add'.tr(),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 18,
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
