import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_dialog.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_empty_state.dart';
import 'package:anoxia/framework/domain/user_vo.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_search_bar.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_search_skeleton.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_user_card.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// 添加好友页面
///
/// 提供搜索用户并发送好友请求的功能，支持按昵称或用户名搜索、
/// 区分已添加好友并通过对话框发送验证消息。
class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key, this.initialKeyword});

  final String? initialKeyword;

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSearchServiceProvider.notifier).clearResults();
      final keyword = widget.initialKeyword?.trim() ?? '';
      if (keyword.isNotEmpty) {
        _searchController.text = keyword;
        _performSearch(keyword);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchService = ref.watch(userSearchServiceProvider);
    final contactListAsync = ref.watch(contactListServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDesktop =
        DeviceUtil.isRealDesktop() ||
        (DeviceUtil.isWeb && DeviceUtil.isDesktop(context));

    final contactMap = contactListAsync.value ?? {};
    final contactIds = contactMap.keys.toSet();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
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
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: HugeIcon(
            icon: isDesktop
                ? HugeIcons.strokeRoundedCancel01
                : HugeIcons.strokeRoundedArrowLeft01,
            color: colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUserAdd02,
                          size: 19,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'add_friend_search_to_add'.tr(),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'add_friend_input_hint'.tr(),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: searchService.rows.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final user = searchService.rows[index];
                              final isFriend = contactIds.contains(user.userId);

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 220),
                                child: SlideAnimation(
                                  verticalOffset: 16,
                                  child: FadeInAnimation(
                                    child: AddFriendUserCard(
                                      user: user,
                                      isFriend: isFriend,
                                      onTapAdd: () => _sendFriendRequest(user),
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
      Toast.showToast('add_friend_search_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest(UserVO user) async {
    final result = await AddFriendDialog.show(context, user);
    if (!mounted) return;
    // 用户取消（返回 null）时不展示任何提示
    if (result == null) return;

    Toast.showToast(
      result
          ? 'add_friend_request_sent'.tr()
          : 'add_friend_request_failed'.tr(),
      type: result ? ToastType.success : ToastType.error,
    );
  }
}
