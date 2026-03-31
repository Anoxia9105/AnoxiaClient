import 'package:anoxia/pages/chat/call/component/ParticipantTile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LayoutRoomCarouselWidget extends StatelessWidget {
  final List<Participant> participants;

  const LayoutRoomCarouselWidget({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    final remote = participants.whereType<RemoteParticipant>().firstOrNull;
    final local = participants.whereType<LocalParticipant>().firstOrNull;

    return Stack(
      children: [
        // 远端全屏
        if (remote != null)
          Positioned.fill(
            child: ParticipantTile(
              participant: remote,
              key: ValueKey(remote.sid),
            ),
          )
        else if (local != null)
          Positioned.fill(
            child: ParticipantTile(
              participant: local,
              key: ValueKey(local.sid),
            ),
          ),

        // 本地小窗右下角
        if (remote != null && local != null)
          Positioned(
            right: 16,
            bottom: 16,
            width: 120,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ParticipantTile(
                participant: local,
                key: ValueKey('${local.sid}-pip'),
              ),
            ),
          ),
      ],
    );
  }
}