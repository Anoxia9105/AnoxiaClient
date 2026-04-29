import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/UserVO.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// 添加朋友页面
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
    // 页面加载时清空上次的搜索结果
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

    // 获取联系人 ID 列表，用于快速检查
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(18),
                color: colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'add_friend_search_hint'.tr(),
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colorScheme.outline,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: colorScheme.outline,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(userSearchServiceProvider.notifier).clearResults();
                                    setState(() {});
                                  },
                                  splashRadius: 20,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 14.0,
                          ),
                        ),
                        style: textTheme.bodyMedium?.copyWith(fontSize: 15),
                        onSubmitted: (value) {
                          _performSearch(value);
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8, right: 8),
                      height: 40,
                      child: VerticalDivider(
                        color: colorScheme.outlineVariant,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: _isSearching
                            ? null
                            : () => _performSearch(_searchController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                          textStyle: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.search_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 搜索结果
            Expanded(
              child: searchService.rows.isNotEmpty
                  ? AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        itemCount: searchService.rows.length,
                        itemBuilder: (context, index) {
                          final user = searchService.rows[index];

                          // 检查是否已经是好友
                          final isFriend = contactIds.contains(user.userId);

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 300),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: !isFriend
                                          ? () {
                                              _showAddFriendDialog(user);
                                            }
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Row(
                                          children: [
                                            AvatarWidget(
                                              url: user.avatar,
                                              name: user.nickName,
                                              size: 64,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.nickName,
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 17,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'add_friend_username'.tr(
                                                      args: [user.userName],
                                                    ),
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .outline,
                                                          fontSize: 14,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (user.phonenumber != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        'add_friend_phone'.tr(
                                                          args: [
                                                            user.phonenumber!,
                                                          ],
                                                        ),
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: colorScheme
                                                                  .outline,
                                                              fontSize: 14,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (isFriend)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .surfaceVariant,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: colorScheme
                                                        .outlineVariant,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'add_friend_already_friend'
                                                      .tr(),
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme.outline,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                ),
                                              )
                                            else
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: colorScheme.primary
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    _showAddFriendDialog(user);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        colorScheme.primary,
                                                    foregroundColor:
                                                        colorScheme.onPrimary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 10,
                                                        ),
                                                    elevation: 0,
                                                    textStyle: textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'add_friend_add_btn'.tr(),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : _searchController.text.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch02,
                              size: 72,
                              color: colorScheme.outline.withOpacity(0.6),
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
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedUserAdd02,
                              size: 96,
                              color: colorScheme.primary.withOpacity(0.6),
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
                    ),
            ), // 修复3: 添加缺失的逗号
          ],
        ),
      ),
    );
  }

  /// 执行搜索
  void _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await ref.read(userSearchServiceProvider.notifier).searchUsers(keyword);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('add_friend_search_failed'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 显示添加朋友对话框
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
                  color: Colors.black.withOpacity(0.12),
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
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
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
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
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
                              color: colorScheme.primary.withOpacity(0.2),
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

  /// 发送好友申请
  Future<void> _sendFriendRequest(UserVO user) async {
    setState(() {
      _isSending = true;
    });

    try {
      final success = await ref
          .read(userSearchServiceProvider.notifier)
          .sendContactRequest(user.userId, _remarkController.text);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('add_friend_request_sent'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('add_friend_request_failed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('add_friend_send_failed'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}
