import 'package:anoxia/features/chat/presentation/call/component/command_bar.dart';
import 'package:anoxia/features/chat/presentation/call/component/reaction_overlay.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_screen_widget.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_widget.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/layout_mode.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间主体内容
///
/// 根据房间状态渲染实际的通话界面
class CallWindowRoomBody extends ConsumerStatefulWidget {
  /// 房间状态
  final RoomState roomState;

  /// 房间令牌
  final String token;
  final String title;

  const CallWindowRoomBody({
    super.key,
    required this.roomState,
    required this.token,
    required this.title,
  });

  @override
  ConsumerState<CallWindowRoomBody> createState() => _CallWindowRoomBodyState();
}

class _CallWindowRoomBodyState extends ConsumerState<CallWindowRoomBody> {
  String? _focusedIdentity;

  @override
  Widget build(BuildContext context) {
    final roomState = widget.roomState;
    final token = widget.token;
    final layoutMode = ref.watch(layoutModeProvider(roomState));

    final participants = <Participant>[
      if (roomState.room.localParticipant != null)
        roomState.room.localParticipant!,
      ...roomState.remoteParticipants,
    ];

    final screenSharer = participants.where(_hasActiveScreenShare).firstOrNull;
    final focusedRaw = participants
        .where((p) => p.identity == _focusedIdentity)
        .firstOrNull;
    // 纯头像（无可见视频轨道）不允许成为焦点：点击头像不切换视图，
    // 关摄像头后也自动回落到网格/共享布局，避免头像独占主画面。
    final focused = (focusedRaw != null && _hasVisibleVideo(focusedRaw))
        ? focusedRaw
        : null;

    final notifier = ref.read(roomControllerProvider(token).notifier);

    void onMute(String identity) => notifier.sendMuteCommand(identity, true);
    void onKick(String identity) => notifier.kickParticipant(identity);

    return Stack(
      children: [
        Column(
          children: [
            CommandBar(state: roomState, title: widget.title),
            Expanded(
              child: participants.isEmpty
                  ? Center(child: Text('call_waiting_to_join'.tr()))
                  : _buildLayout(
                      mode: layoutMode,
                      participants: participants,
                      screenSharer: screenSharer,
                      focusedParticipant: focused,
                      handRaiseMap: roomState.handRaiseMap ?? {},
                      onMute: onMute,
                      onKick: onKick,
                    ),
            ),
          ],
        ),

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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 表情反应全屏特效叠加层
        ReactionOverlay(reactions: roomState.reactions ?? []),
      ],
    );
  }

  /// 是否有可见视频轨道（摄像头或屏幕共享其一即可）
  ///
  /// 与 [ParticipantTile] 的显示逻辑对齐：仅 `!muted && subscribed`
  ///（即 `track != null`）的视频轨道才算有画面，纯头像返回 false。
  bool _hasVisibleVideo(Participant p) {
    return p.videoTrackPublications.any(
      (pub) => !pub.muted && pub.subscribed && pub.track is VideoTrack,
    );
  }

  /// 是否正在活跃共享屏幕（静音/未订阅的残留 publication 不算）
  bool _hasActiveScreenShare(Participant p) {
    return p.videoTrackPublications.any(
      (pub) => pub.isScreenShare && !pub.muted && pub.subscribed,
    );
  }

  /// 网格点击：仅有画面的磁贴才能进入焦点/共享大屏，纯头像直接忽略
  void _onGridTap(Participant participant) {
    if (!_hasVisibleVideo(participant)) return;
    setState(() => _focusedIdentity = participant.identity);
  }

  /// 大屏/侧栏点击：纯头像缩略图不允许抢占主画面，点击主画面可取消聚焦
  void _onScreenTap(Participant participant) {
    if (participant.identity != _focusedIdentity &&
        !_hasVisibleVideo(participant)) {
      return;
    }
    setState(() {
      _focusedIdentity = participant.identity == _focusedIdentity
          ? null
          : participant.identity;
    });
  }

  /// 根据布局模式构建对应的布局组件
  Widget _buildLayout({
    required LayoutMode mode,
    required List<Participant> participants,
    required Participant? screenSharer,
    required Participant? focusedParticipant,
    required Map<String, bool> handRaiseMap,
    void Function(String identity)? onMute,
    void Function(String identity)? onKick,
  }) {
    final primary = focusedParticipant ?? screenSharer;
    if (primary != null) {
      return LayoutRoomScreenWidget(
        screenParticipant: primary,
        otherParticipants: participants
            .where((p) => p.sid != primary.sid)
            .toList(),
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
        onParticipantTap: _onScreenTap,
      );
    }
    return switch (mode) {
      LayoutMode.grid => LayoutRoomWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
        onParticipantTap: _onGridTap,
      ),
      LayoutMode.focus =>
        screenSharer == null
            // 防御：mode 与实际轨道状态短暂不一致时回落网格，避免 `!` 崩溃
            ? LayoutRoomWidget(
                participants: participants,
                handRaiseMap: handRaiseMap,
                onMute: onMute,
                onKick: onKick,
                onParticipantTap: _onGridTap,
              )
            : LayoutRoomScreenWidget(
                screenParticipant: screenSharer,
                otherParticipants: participants
                    .where((p) => p.sid != screenSharer.sid)
                    .toList(),
                handRaiseMap: handRaiseMap,
                onMute: onMute,
                onKick: onKick,
                onParticipantTap: _onScreenTap,
              ),
      // 兼容旧值：1v1 不再使用轮播（远端全屏 + 本地画中画），统一降级为网格。
      // ignore: deprecated_member_use_from_same_package
      LayoutMode.carousel => LayoutRoomWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
        onParticipantTap: _onGridTap,
      ),
    };
  }
}
