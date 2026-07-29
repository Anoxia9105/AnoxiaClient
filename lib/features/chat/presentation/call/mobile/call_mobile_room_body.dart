import 'package:anoxia/features/chat/presentation/call/component/reaction_overlay.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
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

    if (isInPipMode) {
      return _buildPipContent(participants, isVideoCall);
    }

    return ColoredBox(
      color: const Color(0xFF0D0F14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideoCall)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 148),
              child: _buildVideoLayout(participants),
            )
          else
            _AudioCallBackground(title: title),
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
      ),
    );
  }

  Widget _buildPipContent(List<Participant> participants, bool isVideoCall) {
    if (!isVideoCall) {
      return const ColoredBox(
        color: Color(0xFF161922),
        child: Center(
          child: Icon(Icons.call_rounded, color: Colors.white, size: 42),
        ),
      );
    }
    final Participant? participant =
        widget.roomState.remoteParticipants.firstOrNull ??
        widget.roomState.room.localParticipant;
    if (participant == null) {
      return const ColoredBox(color: Color(0xFF161922));
    }
    return MobileParticipantSurface(
      participant: participant,
      compact: true,
      showStatus: false,
      borderRadius: 0,
    );
  }

  Widget _buildVideoLayout(List<Participant> participants) {
    if (participants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (participants.length <= 2) {
      return _buildOneToOneLayout(participants);
    }

    final focused = participants
        .where(
          (participant) => participant.identity == _focusedParticipantIdentity,
        )
        .firstOrNull;
    if (focused != null) {
      return _buildFocusLayout(focused, participants);
    }
    return _buildGridLayout(participants);
  }

  Widget _buildOneToOneLayout(List<Participant> participants) {
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
        if (local != null && local != primary)
          Positioned(
            top: 12,
            right: 12,
            width: 104,
            height: 150,
            child: MobileParticipantSurface(
              key: ValueKey('mobile-local-${local.sid}'),
              participant: local,
              compact: true,
              borderRadius: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildGridLayout(List<Participant> participants) {
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
              onTap: () => setState(
                () => _focusedParticipantIdentity = participant.identity,
              ),
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

  Widget _buildFocusLayout(
    Participant focused,
    List<Participant> participants,
  ) {
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
                onTap: () => setState(
                  () => _focusedParticipantIdentity = participant.identity,
                ),
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
                    onPressed: () =>
                        setState(() => _focusedParticipantIdentity = null),
                    icon: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
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

class _AudioCallBackground extends StatelessWidget {
  const _AudioCallBackground({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202638), Color(0xFF11141D), Color(0xFF080A0F)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(size: 260, color: Color(0x334F7DFF)),
          ),
          const Positioned(
            bottom: 100,
            left: -90,
            child: _GlowOrb(size: 240, color: Color(0x2256E39F)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 116),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'call_voice_call_in_progress'.tr(),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 25)],
      ),
    );
  }
}
