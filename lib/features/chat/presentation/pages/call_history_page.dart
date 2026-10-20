import 'dart:async';

import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:anoxia/framework/provider/chat/call/call_history_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 通话记录页面（按房间过滤）
///
/// 从会话详情进入（桌面端弹窗 / 移动端整页，由 presentAdaptivePage 决定），
/// 仅展示当前房间的自身通话记录；不再作为主框架独立页签。
/// - 条目：对端/群名 + 呼出/呼入 + 状态（完成显示时长）+ 服务器时间；
/// - 点击条目关闭本页/弹窗，回到对应会话；
/// - 下拉刷新 + 滚动到底自动加载下一页。
class CallHistoryPage extends ConsumerWidget {
  final String roomId;

  const CallHistoryPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callHistoryListProvider(roomId));
    final colors = Theme.of(context).colorScheme;

    final Widget content;
    if (state.entries.isEmpty && state.initialLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.entries.isEmpty && state.error != null) {
      content = _ErrorView(
        onRetry: () => unawaited(
          ref.read(callHistoryListProvider(roomId).notifier).refresh(),
        ),
      );
    } else if (state.entries.isEmpty) {
      content = _EmptyView(colors: colors);
    } else {
      content = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (notification.depth == 0 &&
              metrics.pixels >= metrics.maxScrollExtent - 240) {
            unawaited(
              ref.read(callHistoryListProvider(roomId).notifier).loadMore(),
            );
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          // 列表上下内填充：条目不贴栏目与底部边缘
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: state.entries.length + 1,
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 0.5, color: colors.outlineVariant),
          itemBuilder: (context, index) {
            if (index == state.entries.length) return _ListFooter(state: state);
            return _CallEntryTile(entry: state.entries[index]);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 16,
        title: Text('call.history'.tr()),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(callHistoryListProvider(roomId).notifier).refresh,
        child: content,
      ),
    );
  }
}

/// 空列表占位
class _EmptyView extends StatelessWidget {
  final ColorScheme colors;

  const _EmptyView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCall,
                  size: 40,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'call.history.empty'.tr(),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 加载失败占位（点击重试）
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  size: 36,
                  color: colors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'call.history.load_failed'.tr(),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: Text('retry'.tr())),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 列表尾部：加载下一页指示 / 没有更多
class _ListFooter extends StatelessWidget {
  final CallHistoryState state;

  const _ListFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'call.history.no_more'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}

/// 单条通话记录
class _CallEntryTile extends StatelessWidget {
  final CallLogEntry entry;

  const _CallEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = entry.displayName.isEmpty
        ? 'call.history.unknown_peer'.tr()
        : entry.displayName;

    return InkWell(
      onTap: () => _openRoom(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AvatarWidget(url: entry.peerAvatar, name: title, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _subtitle(colors),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateUtil.formatTime(entry.startAt),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 副标题行：呼出/呼入 + 状态（进行中/已拒绝/已取消/时长）
  Widget _subtitle(ColorScheme colors) {
    final directionKey = entry.outgoing
        ? 'call.history.outgoing'
        : 'call.history.incoming';
    final directionIcon = entry.outgoing
        ? Icons.call_made
        : Icons.call_received;

    final (String statusText, Color statusColor) = switch (entry.status) {
      CallLogStatus.ongoing => (
        'call.history.ongoing'.tr(),
        colors.primary,
      ),
      CallLogStatus.rejected => (
        'call.history.rejected'.tr(),
        colors.error,
      ),
      CallLogStatus.canceled => (
        'call.history.canceled'.tr(),
        colors.onSurfaceVariant,
      ),
      CallLogStatus.completed => (
        entry.durationText ?? '',
        colors.onSurfaceVariant,
      ),
    };

    return Row(
      children: [
        Icon(directionIcon, size: 13, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          directionKey.tr(),
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '·',
          style: TextStyle(fontSize: 12, color: colors.outlineVariant),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
        ),
      ],
    );
  }

  /// 返回对应会话：本页从会话详情打开（桌面弹窗 / 移动端整页），直接关闭即可。
  void _openRoom(BuildContext context) {
    Navigator.of(context).maybePop();
  }
}
