import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 添加好友搜索栏组件
///
/// 提供搜索用户的输入框，支持搜索输入、清除按钮、搜索按钮加载状态
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'add_friend_search_hint'.tr(),
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 14,
                ),
                prefixIcon: Center(
                  child: SizedBox.square(
                    dimension: 14,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch02,
                      color: colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 36,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: colorScheme.outline,
                          size: 18,
                        ),
                        onPressed: onClear,
                        splashRadius: 18,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              onSubmitted: onSubmitted,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: SpacingToken.sm),
          Tooltip(
            message: 'add_friend_search_btn'.tr(),
            child: FilledButton(
              onPressed: isSearching || controller.text.trim().isEmpty
                  ? null
                  : onSearch,
              style: FilledButton.styleFrom(
                minimumSize: const Size(46, 46),
                maximumSize: const Size(46, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                ),
                padding: EdgeInsets.zero,
              ),
              child: isSearching
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 19,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
