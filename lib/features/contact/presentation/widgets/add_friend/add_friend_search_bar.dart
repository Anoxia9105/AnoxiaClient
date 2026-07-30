import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
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
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                    size: 20,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: textTheme.bodyMedium?.copyWith(fontSize: 15),
                onSubmitted: onSubmitted,
                onChanged: onChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: FilledButton(
                onPressed: isSearching ? null : onSearch,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(42, 42),
                  maximumSize: const Size(42, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: isSearching
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
