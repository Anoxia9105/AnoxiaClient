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
  }

  List<Participant> get _participants => [
    if (widget.roomState.room.localParticipant != null)
      widget.roomState.room.localParticipant!,
    ...widget.roomState.remoteParticipants,
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    final isVideoCall = session?.initialMedia == CallInitialMedia.video;
    final isInPipMode = session?.isInPipMode ?? false;
    final title = session?.title ?? '';
    final roomId = session?.roomId ?? '';
    final participants = _participants;
    // 音频通话页中央头像：取房间头像（1:1 即对方头像，群聊为群头像）
    final roomAvatar =
        roomId.isEmpty ? '' : ref.watch(currentRoomProvider(roomId))?.roomAvatar ?? '';

    if (isInPipMode) {
      return _buildPipContent(participants, isVideoCall);
    }

    // 背景由外层 MobileCallPage 的统一渐变绘制（AppBar 与正文无缝衔接），
    // 这里不再重复绘制渐变，避免「appbar 区域与页面颜色不一致」。
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideoCall)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 148),
            child: MobileVideoLayout(
              participants: participants,
              focusedParticipantIdentity: _focusedParticipantIdentity,
              onFocusChanged: (identity) {
                setState(() => _focusedParticipantIdentity = identity);
              },
            ),
          )
        else
          AudioCallBackground(title: title, avatarUrl: roomAvatar),
        Align(
          alignment: Alignment.bottomCenter,
          child: MobileCallControls(
            state: widget.roomState,
            roomId: roomId,
            title: title,
            isVideoCall: isVideoCall,
          ),
        ),
        ReactionOverlay(reactions: widget.roomState.reactions ?? []),
      ],
    );
  }

  Widget _buildPipContent(List<Participant> participants, bool isVideoCall) {
    if (!isVideoCall) {
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
    );
  }
}

/// 移动端视频布局组件
///
/// 所有人数统一使用网格布局：
/// - 1人：单画面占满
/// - 2人（1v1）：等分网格（竖屏上下分、横屏左右分），不再使用主画面 + 小窗
/// - 3人以上：多列网格
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

    if (participants.length <= 2) {
      return _buildOneToOneGridLayout();
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

  /// 1v1 网格布局：两路画面等分占满可用区域。
  ///
  /// 竖屏上下分、横屏左右分，不再使用远端全屏 + 本地小窗；
  /// 每块磁贴均为 cover 填充铺满，无空白、无挤压。
  /// 点击磁贴进入聚焦模式，与多人网格行为一致。
  Widget _buildOneToOneGridLayout() {
    if (participants.length == 1) {
      return MobileParticipantSurface(
        key: ValueKey('mobile-grid-${participants.first.sid}'),
        participant: participants.first,
        borderRadius: 22,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > constraints.maxHeight;
        Widget tile(Participant p) => Expanded(
          child: GestureDetector(
            onTap: () => onFocusChanged(p.identity),
            child: MobileParticipantSurface(
              key: ValueKey('mobile-grid-${p.sid}'),
              participant: p,
              borderRadius: 16,
            ),
          ),
        );
        final tiles = [tile(participants[0]), tile(participants[1])];
        if (horizontal) {
          return Row(
            children: [tiles[0], const SizedBox(width: 8), tiles[1]],
          );
        }
        return Column(
          children: [tiles[0], const SizedBox(height: 8), tiles[1]],
        );
      },
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