import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LayoutRoomCarouselWidget extends StatelessWidget {
  final List<Participant> participants;
  final Map<String, bool> handRaiseMap;
  final void Function(String identity)? onMute;
  final void Function(String identity)? onKick;

  const LayoutRoomCarouselWidget({
    super.key,
    required this.participants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    final remote = participants.whereType<RemoteParticipant>().firstOrNull;
    final local = participants.whereType<LocalParticipant>().firstOrNull;

    return Stack(
      children: [
        // 远端全屏（优先），没有远端则显示本地
        if (remote != null)
          Positioned.fill(
            child: ParticipantTile(
              participant: remote,
              handRaised: handRaiseMap[remote.identity] == true,
              onMute: onMute,
              onKick: onKick,
              key: ValueKey(remote.sid),
            ),
          )
        else if (local != null)
          Positioned.fill(
            child: ParticipantTile(
              participant: local,
              handRaised: handRaiseMap[local.identity] == true,
              key: ValueKey(local.sid),
            ),
          ),

        // 本地小窗右下角（仅在有远端时显示）
        if (remote != null && local != null)
          Positioned(
            right: 16,
            bottom: 16,
            width: 150,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ParticipantTile(
                participant: local,
                handRaised: handRaiseMap[local.identity] == true,
                key: ValueKey('${local.sid}-pip'),
              ),
            ),
          ),
      ],
    );
  }
}
