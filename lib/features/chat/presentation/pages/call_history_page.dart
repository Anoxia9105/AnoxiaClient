import 'dart:async';

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
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
          padding: const EdgeInsets.all(SpacingToken.lg),
          itemCount: state.entries.length + 2,
          separatorBuilder: (context, index) =>
              const SizedBox(height: SpacingToken.md),
          itemBuilder: (context, index) {
            if (index == 0) return _HistoryHeader(total: state.total);
            if (index == state.entries.length + 1) {
              return _ListFooter(
                state: state,
                onLoadMore: () => ref
                    .read(callHistoryListProvider(roomId).notifier)
                    .loadMore(),
              );
            }
            final entry = state.entries[index - 1];
            final date = DateTime.fromMillisecondsSinceEpoch(entry.startAt);
            final previousDate = index > 1
                ? DateTime.fromMillisecondsSinceEpoch(
                    state.entries[index - 2].startAt,
                  )
                : null;
            final newDay =
                previousDate == null ||
                !DateUtils.isSameDay(date, previousDate);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (newDay)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: SpacingToken.sm,
                      bottom: SpacingToken.md,
                      left: SpacingToken.xs,
                    ),
                    child: Text(
                      _dayLabel(date, context),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                _CallEntryTile(entry: entry),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 16,
        title: Text('call.history'.tr()),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
        ),
        actions: [
          IconButton(
            tooltip: 'call.history.refresh'.tr(),
            onPressed: state.initialLoading || state.loadingMore
                ? null
                : () => ref
                      .read(callHistoryListProvider(roomId).notifier)
                      .refresh(),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
          ),
          const SizedBox(width: SpacingToken.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(callHistoryListProvider(roomId).notifier).refresh,
        child: content,
      ),
    );
  }
}

String _dayLabel(DateTime date, BuildContext context) {
  final today = DateUtils.dateOnly(DateTime.now());
  if (DateUtils.isSameDay(date, today)) return 'call.history.today'.tr();
  if (DateUtils.isSameDay(
    date,
    DateTime(today.year, today.month, today.day - 1),
  )) {
    return 'call.history.yesterday'.tr();
  }
  return DateFormat.yMMMd(context.locale.toString()).format(date);
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(SpacingToken.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCall,
            size: 28,
            color: colors.primary,
          ),
          const SizedBox(width: SpacingToken.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'call.history.scope'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: SpacingToken.xs),
                Text(
                  'call.history.total'.tr(args: ['$total']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'call.history.return'.tr(),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 20,
                color: colors.primary,
              ),
            ),
          ),
        ],
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
  final Future<void> Function() onLoadMore;

  const _ListFooter({required this.state, required this.onLoadMore});

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
    return Center(
      child: TextButton.icon(
        onPressed: onLoadMore,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowDown01,
          size: 18,
        ),
        label: Text('chat_media_timeline_load_more'.tr()),
      ),
    );
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

    final statusColor = switch (entry.status) {
      CallLogStatus.completed =>
        Theme.of(context).extension<AppColors>()?.success ?? colors.primary,
      CallLogStatus.rejected => colors.error,
      CallLogStatus.ongoing => colors.primary,
      CallLogStatus.canceled => colors.onSurfaceVariant,
    };
    final status = switch (entry.status) {
      CallLogStatus.completed => 'call.history.completed',
      CallLogStatus.rejected => 'call.history.rejected',
      CallLogStatus.ongoing => 'call.history.ongoing',
      CallLogStatus.canceled => 'call.history.canceled',
    };
    final date = DateTime.fromMillisecondsSinceEpoch(entry.startAt);
    return Tooltip(
      message: 'call.history.return'.tr(),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: () => _openRoom(context),
          child: Padding(
            padding: const EdgeInsets.all(SpacingToken.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(RadiusToken.lg),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: entry.outgoing
                          ? HugeIcons.strokeRoundedArrowUpRight01
                          : HugeIcons.strokeRoundedArrowDownLeft01,
                      size: 24,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (entry.outgoing
                                ? 'call.history.outgoing'
                                : 'call.history.incoming')
                            .tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingToken.xs),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SpacingToken.sm),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedTime01,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: SpacingToken.xs),
                          Flexible(
                            child: Text(
                              DateFormat.Hm(
                                context.locale.toString(),
                              ).format(date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                          if (entry.status == CallLogStatus.completed) ...[
                            const SizedBox(width: SpacingToken.md),
                            Flexible(
                              child: Text(
                                _duration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: colors.onSurface),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingToken.sm,
                    vertical: SpacingToken.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(RadiusToken.sm),
                  ),
                  child: Text(
                    status.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
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

  String get _duration {
    if (entry.durationText?.isNotEmpty == true) return entry.durationText!;
    final seconds = entry.durationSec;
    if (seconds == null || seconds < 0) return '—';
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60) % 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:$rest'
        : '$minutes:$rest';
  }

  /// 返回对应会话：本页从会话详情打开（桌面弹窗 / 移动端整页），直接关闭即可。
  void _openRoom(BuildContext context) {
    Navigator.of(context).maybePop();
  }
}
