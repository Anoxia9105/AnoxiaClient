// 群组公告横幅组件，在聊天页面顶部以横幅形式展示群组公告。
//
// 支持查看公告详情和关闭横幅，关闭后相同内容的公告不再显示。
import 'package:anoxia/features/chat/presentation/pages/group_announcement_detail_page.dart';
import 'package:anoxia/framework/provider/chat/room/group_announcement_dismissal_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组公告横幅。
///
/// 在群组聊天页面顶部显示公告内容摘要，点击可查看详情，支持关闭。
class GroupAnnouncementBanner extends ConsumerWidget {
  /// 群组房间 ID。
  final String roomId;

  /// 公告内容。
  final String announcement;

  const GroupAnnouncementBanner({
    super.key,
    required this.roomId,
    required this.announcement,
  });

  /// 打开公告详情页面。
  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupAnnouncementDetailPage(roomId: roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = announcement.trim();
    final dismissedContent = ref.watch(
      groupAnnouncementDismissalProvider.select((state) => state[roomId]),
    );
    if (content.isEmpty || dismissedContent == content) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.campaign_outlined,
              size: 19,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => _openDetail(context),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => ref
                  .read(groupAnnouncementDismissalProvider.notifier)
                  .dismiss(roomId, content),
              tooltip: 'chat_group_announcement_close'.tr(),
              icon: const Icon(Icons.close, size: 18),
              color: colorScheme.onSecondaryContainer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}