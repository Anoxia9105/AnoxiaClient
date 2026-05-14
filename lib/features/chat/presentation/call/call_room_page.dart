import 'package:anoxia/framework/provider/chat/call/LayoutMode.dart';
import 'package:anoxia/framework/provider/chat/call/history_panel_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/features/chat/presentation/call/component/command_bar.dart';
import 'package:anoxia/features/chat/presentation/call/room_layout/layout_room_carousel_widget.dart';
import 'package:anoxia/features/chat/presentation/call/room_layout/layout_room_screen_widget.dart';
import 'package:anoxia/features/chat/presentation/call/room_layout/layout_room_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:window_manager/window_manager.dart';

class CallRoomPage extends ConsumerWidget {
  final String token;
  const CallRoomPage({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomControllerProvider(token));

    return Scaffold(
      body: roomAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString(), ref, token),
        data: (roomState) => _CallRoomBody(roomState: roomState, token: token),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ring_volume_rounded, size: 34),
            const SizedBox(height: 14),
            Text(
              'call_connecting_to_room'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'call_please_wait'.tr(),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref, String token) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 24),
            Text(
              'call_connection_failed'.tr(),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ref.invalidate(roomControllerProvider(token)),
                child: Text(
                  'call_retry'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallRoomBody extends ConsumerWidget {
  final RoomState roomState;
  final String token;

  const _CallRoomBody({required this.roomState, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutModeProvider(roomState));
    final showHistory = ref.watch(historyPanelProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (roomState.connectionError == 'token_expired' ||
          roomState.connectionError == 'max_reconnect_attempts_exceeded') {
        windowManager.close();
      }
    });

    final participants = <Participant>[
      if (roomState.room.localParticipant != null)
        roomState.room.localParticipant!,
      ...roomState.remoteParticipants,
    ];

    final screenSharer = participants
        .where((p) => p.videoTrackPublications.any((pub) => pub.isScreenShare))
        .firstOrNull;

    final notifier = ref.read(roomControllerProvider(token).notifier);

    // 静音回调：向目标参与者发送静音指令
    void onMute(String identity) => notifier.sendMuteCommand(identity, true);

    // 踢出回调：调用服务端踢出接口
    void onKick(String identity) => notifier.kickParticipant(identity);

    return Stack(
      children: [
        Column(
          children: [
            CommandBar(state: roomState),
            Expanded(
              child: Row(
                children: [
                  // 主视频区域
                  Expanded(
                    child: participants.isEmpty
                        ? Center(child: Text('call_waiting_to_join'.tr()))
                        : _buildLayout(
                            mode: layoutMode,
                            participants: participants,
                            screenSharer: screenSharer,
                            handRaiseMap: roomState.handRaiseMap ?? {},
                            onMute: onMute,
                            onKick: onKick,
                          ),
                  ),
                  // 历史面板
                  if (showHistory)
                    _HistoryPanel(history: roomState.reactions ?? []),
                ],
              ),
            ),
          ],
        ),

        // 重连遮罩
        if (roomState.isReconnecting)
          Positioned(
            top: kToolbarHeight + 8,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'call_reconnecting'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'call_reconnecting_hint'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLayout({
    required LayoutMode mode,
    required List<Participant> participants,
    required Participant? screenSharer,
    required Map<String, bool> handRaiseMap,
    void Function(String identity)? onMute,
    void Function(String identity)? onKick,
  }) {
    return switch (mode) {
      LayoutMode.grid => LayoutRoomWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.focus => LayoutRoomScreenWidget(
        screenParticipant: screenSharer!,
        otherParticipants: participants
            .where((p) => p.sid != screenSharer.sid)
            .toList(),
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.carousel => LayoutRoomCarouselWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
    };
  }
}

// ── 历史面板 ──────────────────────────────

class _HistoryPanel extends ConsumerWidget {
  final List<ReactionItem> history;
  const _HistoryPanel({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final border = BorderSide(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      width: 1,
    );

    return Container(
      width: 280,
      decoration: BoxDecoration(border: Border(left: border)),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: border)),
            child: Row(
              children: [
                const Text(
                  '聊天记录',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => ref.read(historyPanelProvider.notifier).close(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      '暂无消息',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: history.length,
                    itemBuilder: (_, i) => _HistoryItem(item: history[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ReactionItem item;
  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (item.avatar?.isNotEmpty == true)
                ? NetworkImage(item.avatar!)
                : null,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: (item.avatar?.isNotEmpty == true)
                ? null
                : Text(
                    (item.name.isNotEmpty ? item.name[0] : '?').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name.isNotEmpty ? item.name : item.uid,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.message, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
