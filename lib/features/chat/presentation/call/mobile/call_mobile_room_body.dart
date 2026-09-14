import 'package:anoxia/features/chat/presentation/call/component/call_loading_state.dart';
import 'package:anoxia/features/chat/presentation/call/component/reaction_overlay.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/audio_call_background.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import 'draggable_self_view.dart';
import 'mobile_call_controls.dart';
import 'mobile_participant_surface.dart';

class CallMobileRoomBody extends ConsumerStatefulWidget {
  const CallMobileRoomBody({
    super.key,
    required this.roomState,
    required this.token,
  });

  final RoomState roomState;
  final String token;

  @override
  ConsumerState<CallMobileRoomBody> createState() => _CallMobileRoomBodyState();
}

class _CallMobileRoomBodyState extends ConsumerState<CallMobileRoomBody> {
  String? _focusedParticipantIdentity;

  /// 上一次渲染时的共享者 sid，用于感知「共享开始/停止/换人」
  String? _lastSharerSid;

  @override
  void didUpdateWidget(covariant CallMobileRoomBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusedIdentity = _focusedParticipantIdentity;
    if (focusedIdentity != null &&
        !_participants.any(
          (participant) => participant.identity == focusedIdentity,
        )) {
      _focusedParticipantIdentity = null;
    }
    // 共享者发生变化时清掉聚焦：否则上一轮聚焦的人会顶掉刚开始的共享画面
    final sharerSid = _sharerSid;
    if (sharerSid != _lastSharerSid) {
      _lastSharerSid = sharerSid;
      _focusedParticipantIdentity = null;
    }
  }

  List<Participant> get _participants => [
    if (widget.roomState.room.localParticipant != null)
      widget.roomState.room.localParticipant!,
    ...widget.roomState.remoteParticipants,
  ];

  /// 当前正在共享屏幕的参与者 sid
  String? get _sharerSid =>
      _participants.where(_isSharingScreen).firstOrNull?.sid;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    final isVideoCall = session?.initialMedia == CallInitialMedia.video;
    final isInPipMode = session?.isInPipMode ?? false;
    final title = session?.title ?? '';
    final roomId = session?.roomId ?? '';
    final participants = _participants;
    // 有人在共享屏幕（含语音通话中被共享的场景）
    final screenSharer = participants.where(_isSharingScreen).firstOrNull;
    // 音频通话页中央头像：取房间头像（1:1 即对方头像，群聊为群头像）
    final roomAvatar =
        roomId.isEmpty ? '' : ref.watch(currentRoomProvider(roomId))?.roomAvatar ?? '';

    if (isInPipMode) {
      return _buildPipContent(participants, isVideoCall, screenSharer);
    }

    // 语音通话下有人共享屏幕时也要展示共享内容，不能只画音频背景。
    final showVideoSurface = isVideoCall || screenSharer != null;
    // 底部控制区预留高度：手机 Web 横屏等矮屏场景收紧，避免画面被压扁
    final bottomInset = _controlsReservedHeight(context);
    final compactControls = bottomInset < _controlsInsetDefault;

    // 背景由外层 MobileCallPage 的统一渐变绘制（AppBar 与正文无缝衔接），
    // 这里不再重复绘制渐变，避免「appbar 区域与页面颜色不一致」。
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showVideoSurface)
          Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, bottomInset),
            child: MobileVideoLayout(
              participants: participants,
              focusedParticipantIdentity: _focusedParticipantIdentity,
              onFocusChanged: (identity) {
                setState(() => _focusedParticipantIdentity = identity);
              },
            ),
          )
        else
          AudioCallBackground(
            title: title,
            avatarUrl: roomAvatar,
            participantCount: participants.length,
          ),
        // 视频画面底部叠一层主题色渐变，保证悬浮的控制栏/计时器始终可读
        // （顶部由 AppBar 所在的渐变外壳承接，无需重复遮罩）
        if (showVideoSurface)
          _CallEdgeScrim(top: false, height: bottomInset + 24),
        Align(
          alignment: Alignment.bottomCenter,
          child: MobileCallControls(
            state: widget.roomState,
            roomId: roomId,
            title: title,
            isVideoCall: isVideoCall,
            compact: compactControls,
          ),
        ),
        ReactionOverlay(reactions: widget.roomState.reactions ?? []),
      ],
    );
  }

  Widget _buildPipContent(
    List<Participant> participants,
    bool isVideoCall,
    Participant? screenSharer,
  ) {
    if (!isVideoCall && screenSharer == null) {
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedCall02,
          color: cs.primary,
          size: 28,
        ),
      );
    }
    final Participant? participant =
        screenSharer ??
        widget.roomState.remoteParticipants.firstOrNull ??
        widget.roomState.room.localParticipant;
    if (participant == null) {
      return const ColoredBox(color: Color(0xFF171A22));
    }
    return MobileParticipantSurface(
      participant: participant,
      compact: true,
      showStatus: false,
      borderRadius: 0,
      fit: screenSharer != null ? VideoViewFit.contain : VideoViewFit.cover,
    );
  }
}

/// 常规竖屏下底部控制区预留高度
const double _controlsInsetDefault = 148;

/// 底部控制区预留高度
///
/// 手机 Web 横屏等矮屏场景下收敛，避免视频/共享画面被控制栏挤扁。
double _controlsReservedHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width > size.height && size.height < 480) return 92;
  if (size.height < 560) return 118;
  return _controlsInsetDefault;
}

/// 通话画面边缘渐变遮罩
///
/// 视频/共享画面亮度不可控，顶部标题栏与底部控制栏直接压在画面上会看不清。
/// 这里用主题 surface 色从边缘向内渐隐（浅色主题为白、深色主题为黑），
/// 保证两种主题下文字与图标都保持对比度；不拦截触摸。
class _CallEdgeScrim extends StatelessWidget {
  const _CallEdgeScrim({required this.top, required this.height});

  /// true 为顶部遮罩，false 为底部遮罩
  final bool top;

  /// 遮罩高度
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [
                  cs.surface.withValues(alpha: 0.6),
                  cs.surface.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 是否正在活跃共享屏幕。
///
/// 依赖 `track != null` 判断可用轨道：远端订阅成功才有 track，
/// 本端（LocalParticipant）发布的轨道 track 恒存在，无需 `subscribed`。
bool _isSharingScreen(Participant p) {
  return p.videoTrackPublications.any(
    (pub) => pub.isScreenShare && !pub.muted && pub.track is VideoTrack,
  );
}

/// 移动端视频布局组件
///
/// 根据参与者数量自动切换布局模式：
/// - 1-2人：一对一布局（主画面 + 小窗）
/// - 3人以上：网格布局
/// - 点击参与者可进入聚焦模式
class MobileVideoLayout extends StatelessWidget {
  const MobileVideoLayout({
    super.key,
    required this.participants,
    required this.focusedParticipantIdentity,
    required this.onFocusChanged,
  });

  final List<Participant> participants;
  final String? focusedParticipantIdentity;
  final void Function(String? identity) onFocusChanged;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const CallLoadingState();
    }

    // 有人在共享屏幕时，优先展示共享画面（与桌面端一致）；
    // 点击底部缩略条可临时把某人切到大屏，再点共享者缩略图切回。
    final screenSharer = participants.where(_isSharingScreen).firstOrNull;
    if (screenSharer != null) {
      final pinned = participants
          .where(
            (participant) =>
                participant.identity == focusedParticipantIdentity &&
                participant.sid != screenSharer.sid,
          )
          .firstOrNull;
      // 矮屏（手机 Web 横屏）收紧缩略条高度，避免挤占主画面
      final thumbHeight = MediaQuery.sizeOf(context).height < 480 ? 68.0 : 92.0;
      return _buildScreenShareLayout(
        screenSharer,
        pinned: pinned,
        thumbHeight: thumbHeight,
      );
    }

    if (participants.length <= 2) {
      return _buildOneToOneLayout();
    }

    final focused = participants
        .where(
          (participant) => participant.identity == focusedParticipantIdentity,
        )
        .firstOrNull;
    if (focused != null) {
      return _buildFocusLayout(focused);
    }
    return _buildGridLayout();
  }

  /// 屏幕共享布局：共享画面大屏 + 底部其他参与者横滑缩略条。
  ///
  /// [pinned] 非空时把该参与者提到大屏，共享者退回缩略条首位，便于一键切回。
  Widget _buildScreenShareLayout(
    Participant sharer, {
    Participant? pinned,
    double thumbHeight = 92,
  }) {
    final primary = pinned ?? sharer;
    final others = <Participant>[
      if (pinned != null) sharer,
      ...participants.where(
        (participant) =>
            participant.sid != primary.sid && participant.sid != sharer.sid,
      ),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileParticipantSurface(
          key: ValueKey('mobile-screen-${primary.sid}'),
          participant: primary,
          borderRadius: 22,
          fit: VideoViewFit.contain,
        ),
        if (others.isNotEmpty)
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            height: thumbHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final p = others[index];
                return GestureDetector(
                  // 点共享者缩略图表示「回到共享画面」，故传 null 清空聚焦
                  onTap: () => onFocusChanged(
                    p.sid == sharer.sid ? null : p.identity,
                  ),
                  child: SizedBox(
                    width: 76,
                    child: MobileParticipantSurface(
                      key: ValueKey('mobile-screen-thumb-${p.sid}'),
                      participant: p,
                      compact: true,
                      borderRadius: 12,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOneToOneLayout() {
    final remote = participants.whereType<RemoteParticipant>().firstOrNull;
    final local = participants.whereType<LocalParticipant>().firstOrNull;
    Participant primary = participants.first;
    if (remote != null) {
      primary = remote;
    } else if (local != null) {
      primary = local;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileParticipantSurface(
          key: ValueKey('mobile-primary-${primary.sid}'),
          participant: primary,
          borderRadius: 22,
        ),
        // 自己的小窗：默认右下角，可拖拽滑动并自动吸边
        if (local != null && local != primary)
          DraggableSelfView(
            key: ValueKey('mobile-local-${local.sid}'),
            participant: local,
          ),
      ],
    );
  }

  Widget _buildGridLayout() {
    final columns = participants.length <= 4 ? 2 : 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (participants.length / columns).ceil();
        final tileWidth =
            (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        final tileHeight =
            (constraints.maxHeight - ((rows - 1) * 8)) / rows.clamp(1, 3);
        final aspectRatio = (tileWidth / tileHeight).clamp(0.64, 1.25);
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: aspectRatio,
          ),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return GestureDetector(
              onTap: () => onFocusChanged(participant.identity),
              child: MobileParticipantSurface(
                key: ValueKey('mobile-grid-${participant.sid}'),
                participant: participant,
                compact: participants.length > 4,
                borderRadius: 16,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFocusLayout(Participant focused) {
    final thumbnails = participants
        .where((participant) => participant.sid != focused.sid)
        .toList();
    return Column(
      children: [
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: thumbnails.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final participant = thumbnails[index];
              return GestureDetector(
                onTap: () => onFocusChanged(participant.identity),
                child: SizedBox(
                  width: 76,
                  child: MobileParticipantSurface(
                    key: ValueKey('mobile-thumb-${participant.sid}'),
                    participant: participant,
                    compact: true,
                    borderRadius: 12,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileParticipantSurface(
                key: ValueKey('mobile-focus-${focused.sid}'),
                participant: focused,
                borderRadius: 22,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'call_back_to_grid_tooltip'.tr(),
                    onPressed: () => onFocusChanged(null),
                    icon: const SizedBox(
                      width: 20,
                      height: 20,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedGridView,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}