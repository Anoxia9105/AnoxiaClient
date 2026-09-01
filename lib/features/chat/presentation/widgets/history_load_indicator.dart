import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../framework/provider/chat/message/room_message_service.dart';

/// 历史消息加载状态指示器
///
/// 显示在消息列表顶部，根据加载状态展示不同 UI：
/// - 加载中：显示旋转进度条
/// - 加载失败：错误提示 + 重试按钮
/// - 空闲：不显示任何内容
class HistoryLoadIndicator extends ConsumerWidget {
  final String roomId;

  const HistoryLoadIndicator({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFetching = ref
        .watch(chatMessagesProvider.notifier)
        .fetchingHistoryRoomIds
        .contains(roomId);
    final errorMsg = ref.watch(historyLoadErrorProvider)[roomId];

    if (isFetching) {
      return _buildLoading();
    }
    if (errorMsg != null) {
      return _buildError(context, ref, errorMsg);
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String errorMsg) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(chatMessagesProvider.notifier).retryHistoryLoad(roomId);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                size: 14,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                errorMsg,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'chat_history_retry'.tr(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}