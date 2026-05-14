import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LayoutRoomWidget extends StatelessWidget {
  final List<Participant> participants;
  final Map<String, bool> handRaiseMap;
  final void Function(String identity)? onMute;
  final void Function(String identity)? onKick;

  const LayoutRoomWidget({
    super.key,
    required this.participants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
  });

  Widget _tile(Participant p) => ParticipantTile(
    participant: p,
    handRaised: handRaiseMap[p.identity] == true,
    onMute: onMute,
    onKick: onKick,
  );

  @override
  Widget build(BuildContext context) {
    final count = participants.length;

    if (count == 0) return const SizedBox.shrink();

    if (count == 1) {
      return _tile(participants[0]);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _tile(participants[0])),
          const SizedBox(width: 4),
          Expanded(child: _tile(participants[1])),
        ],
      );
    }

    if (count <= 4) {
      final row1 = participants.take(2).toList();
      final row2 = participants.skip(2).toList();
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(row1[0])),
                const SizedBox(width: 4),
                Expanded(child: _tile(row1[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(row2[0])),
                const SizedBox(width: 4),
                Expanded(
                  child: row2.length > 1
                      ? _tile(row2[1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 5人以上 GridView
    return GridView.builder(
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 16 / 9,
      ),
      itemBuilder: (context, index) => _tile(participants[index]),
    );
  }
}
