// AI 未读总结（P0-3）：列表顶部引导条 + 总结弹层。
//
// - 引导条：进入会话时若 `unreadCount >= 20` 且聊天 AI 可用才显示
//   （[aiFeatureFlagsProvider].chatAvailable 门控，管理端关闭或上游熔断
//   自动隐藏）；unread 回落到阈值以下自动消失，用户点关闭后本次会话
//   不再打扰（默认在位，随房间切换重置）。
// - 弹层：打开即按当前 UI locale 发起流式总结（按房间 family 缓存），
//   显示完成内容后提供「跳到最早未读」（复用 reply_jump_provider 的
//   nonce 定位请求，与回复跳转同一套消息定位链路）。
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/chat/message/ai_message_tools_provider.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:anoxia/framework/provider/chat/message/reply_jump_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 「AI 总结未读」引导条（进入会话时未读 ≥ 20 展示）
class AiUnreadSummaryBanner extends ConsumerStatefulWidget {
  final String roomId;

  const AiUnreadSummaryBanner({super.key, required this.roomId});

  @override
  ConsumerState<AiUnreadSummaryBanner> createState() =>
      _AiUnreadSummaryBannerState();
}

class _AiUnreadSummaryBannerState extends ConsumerState<AiUnreadSummaryBanner> {
  static const int unreadThreshold = 20;

  String? _mountedRoomId;
  bool _dismissedForRoom = false;

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(currentRoomProvider(widget.roomId));
    final chatAvailable =
        ref.watch(aiFeatureFlagsProvider).value?.chatAvailable ?? false;

    final unread = room?.unreadCount ?? 0;
    final eligible = chatAvailable && !_dismissedForRoom && unread >= unreadThreshold;
    if (!eligible) return const SizedBox.shrink();

    // 用户关闭后，切到其它房间再回来允许再次出现
    if (_mountedRoomId != widget.roomId) {
      _mountedRoomId = widget.roomId;
      _dismissedForRoom = false;
    }

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.72),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 12),
            HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 19,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openSummarySheet(context),
                child: Text(
                  'chat_ai.summarize_unread'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _mountedRoomId = widget.roomId;
                  _dismissedForRoom = true;
                });
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSummarySheet(BuildContext context) {
    presentAdaptivePage(
      context,
      builder: (_) => AiUnreadSummarySheet(roomId: widget.roomId),
    );
  }
}

/// 未读总结弹层（打开即发起，按房间缓存）
class AiUnreadSummarySheet extends ConsumerStatefulWidget {
  final String roomId;

  const AiUnreadSummarySheet({super.key, required this.roomId});

  @override
  ConsumerState<AiUnreadSummarySheet> createState() =>
      _AiUnreadSummarySheetState();
}

class _AiUnreadSummarySheetState extends ConsumerState<AiUnreadSummarySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(aiUnreadSummaryControllerProvider(widget.roomId).notifier)
          .summarize(language: aiLanguageName(context.locale.languageCode));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiUnreadSummaryControllerProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text('chat_ai.summary_sheet_title'.tr()),
        actions: [
          IconButton(
            tooltip: 'chat_ai.jump_to_first_unread'.tr(),
            icon: const Icon(Icons.first_page_outlined),
            onPressed: () => _jumpToFirstUnread(context, state.firstUnreadMessageId),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryBody(roomId: widget.roomId, state: state),
              // 文本结论前置为可选项
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: state.firstUnreadMessageId == null
                    ? null
                    : () => _jumpToFirstUnread(
                        context,
                        state.firstUnreadMessageId,
                      ),
                icon: const Icon(Icons.first_page_outlined),
                label: Text('chat_ai.jump_to_first_unread'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToFirstUnread(BuildContext context, String? messageId) {
    final id = messageId;
    if (id == null || id.isEmpty) return;
    ref
        .read(replyJumpControllerProvider.notifier)
        .jumpTo(roomId: widget.roomId, messageId: id);
    Navigator.of(context).pop();
  }
}

class _SummaryBody extends ConsumerWidget {
  final String roomId;
  final AiToolState state;

  const _SummaryBody({required this.roomId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 早期未拉到状态（首个 postFrame 之前）不需要骨架，直接合并到
    // streaming 占位（总结启动是毫秒级本地查询）。
    if (state.error != null) {
      final message = state.error!.startsWith('chat_ai.')
          ? state.error!.tr()
          : state.error!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref
                  .read(aiUnreadSummaryControllerProvider(roomId).notifier)
                  .reset();
              ref
                  .read(aiUnreadSummaryControllerProvider(roomId).notifier)
                  .summarize(language: aiLanguageName(context.locale.languageCode));
            },
            icon: const Icon(Icons.refresh_outlined),
            label: Text('chat_media_timeline_retry'.tr()),
          ),
        ],
      );
    }

    if (state.isEmptyResult) {
      return Text(
        'chat_ai.summary_empty'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (state.hasContent) {
      return SelectableText(
        state.text!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'chat_ai.summarizing'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
