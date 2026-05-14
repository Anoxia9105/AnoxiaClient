import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend_widgets.dart';
import 'package:anoxia/framework/domain/UserVO.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key});

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSearchServiceProvider.notifier).clearResults();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchService = ref.watch(userSearchServiceProvider);
    final contactListAsync = ref.watch(contactListServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final contactMap = contactListAsync.value ?? {};
    final contactIds = contactMap.keys.toSet();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'add_friend_title'.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AddFriendSearchBar(
              controller: _searchController,
              isSearching: _isSearching,
              onSearch: () => _performSearch(_searchController.text),
              onClear: () {
                _searchController.clear();
                ref.read(userSearchServiceProvider.notifier).clearResults();
                setState(() {});
              },
              onSubmitted: _performSearch,
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: _isSearching
                  ? const AddFriendSearchSkeleton()
                  : searchService.rows.isNotEmpty
                  ? AnimationLimiter(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        itemCount: searchService.rows.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = searchService.rows[index];
                          final isFriend = contactIds.contains(user.userId);

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 260),
                            child: SlideAnimation(
                              verticalOffset: 28,
                              child: FadeInAnimation(
                                child: AddFriendUserCard(
                                  user: user,
                                  isFriend: isFriend,
                                  onTapAdd: () => _showAddFriendDialog(user),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : AddFriendEmptyState(
                      hasKeyword: _searchController.text.isNotEmpty,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await ref.read(userSearchServiceProvider.notifier).searchUsers(keyword);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        text: 'add_friend_search_failed'.tr(),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showAddFriendDialog(UserVO user) {
    _remarkController.clear();

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.85),
                        colorScheme.secondaryContainer.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      AvatarWidget(
                        url: user.avatar,
                        name: user.nickName,
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nickName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'add_friend_username'.tr(args: [user.userName]),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (user.phonenumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.7,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android_outlined,
                          size: 18,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user.phonenumber!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _remarkController,
                  decoration: InputDecoration(
                    hintText: 'add_friend_verify_hint'.tr(),
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  style: textTheme.bodyMedium?.copyWith(fontSize: 15),
                  maxLines: 3,
                  maxLength: 50,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                          textStyle: textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Text('add_friend_cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSending
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await _sendFriendRequest(user);
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            textStyle: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('add_friend_send'.tr()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendFriendRequest(UserVO user) async {
    setState(() {
      _isSending = true;
    });

    try {
      final success = await ref
          .read(userSearchServiceProvider.notifier)
          .sendContactRequest(user.userId, _remarkController.text);

      if (!mounted) return;

      if (success) {
        _showSnack(
          text: 'add_friend_request_sent'.tr(),
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
      } else {
        _showSnack(
          text: 'add_friend_request_failed'.tr(),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        text: 'add_friend_send_failed'.tr(),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnack({required String text, required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
