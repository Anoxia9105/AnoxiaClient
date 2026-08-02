import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/new_friends/new_friends_request_tile.dart';
import 'package:anoxia/features/contact/presentation/widgets/new_friends/new_friends_skeleton.dart';
import 'package:anoxia/features/contact/presentation/widgets/new_friends/new_friends_status_buttons.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hugeicons/hugeicons.dart';

/// 新好友请求页面
///
/// 显示待处理的好友请求列表，支持接受和拒绝请求。
class NewFriendsPage extends ConsumerStatefulWidget {
  const NewFriendsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewFriendsPageState();
}

class _NewFriendsPageState extends ConsumerState<NewFriendsPage> {
  void _openAddFriend() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddFriendPage()));
  }

  /// 将请求时间格式化为微信风格相对时间
  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    return DateUtil.formatWeChatTimeDivider(
      date.millisecondsSinceEpoch,
      context.locale.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(contactRequestsServiceProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('contact_new_friends_title'.tr())),
      body: requestAsync.when(
        data: (req) {
          if (req.isEmpty) {
            return _EmptyState(onAddFriend: _openAddFriend);
          }
          return AnimationLimiter(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: req.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = req[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 260),
                  child: SlideAnimation(
                    verticalOffset: 20,
                    child: FadeInAnimation(
                      child: NewFriendsRequestTile(
                        avatar: request.avatar ?? '',
                        nickName: request.nickName ?? '',
                        remark: request.requestRemark ?? '',
                        createdAtText: _formatTime(request.createdAt),
                        trailing: NewFriendsStatusButtons(
                          status: request.status,
                          onAccept: () => ref
                              .read(contactRequestsServiceProvider.notifier)
                              .acceptRequest(request.id ?? 0, true),
                          onReject: () => ref
                              .read(contactRequestsServiceProvider.notifier)
                              .acceptRequest(request.id ?? 0, false),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const NewFriendsSkeleton(),
        error: (err, stack) => _ErrorState(
          message: '${'contact_load_failed_with_error'.tr()}: $err',
          onRetry: () =>
              ref.read(contactRequestsServiceProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

/// 空状态：无好友请求时展示引导
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddFriend;

  const _EmptyState({required this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.14),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUserAdd02,
                size: 42,
                color: cs.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'contact_no_new_friends'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'add_friend_search_to_add'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onAddFriend,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserAdd01,
                size: 18,
              ),
              label: Text('add_friend_title'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 错误状态：加载失败时提供重试
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: 32,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text('call_window_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
