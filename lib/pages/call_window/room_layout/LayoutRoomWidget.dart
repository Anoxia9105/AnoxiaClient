import 'package:anoxia/pages/call_window/component/ParticipantTile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LayoutRoomWidget extends StatefulWidget {
  final List<Participant> participants;
  const LayoutRoomWidget({super.key, required this.participants});

  @override
  State<LayoutRoomWidget> createState() => _LayoutRoomWidgetState();
}

class _LayoutRoomWidgetState extends State<LayoutRoomWidget> {
  @override
  Widget build(BuildContext context) {
    final count = widget.participants.length;
    final participants = widget.participants;

    if (count == 1) {
      return ParticipantTile(participant: participants[0]);
    }
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: ParticipantTile(participant: participants[0])),
          Expanded(child: ParticipantTile(participant: participants[1])),
        ],
      );
    }
    // 3-4人：田字格 (2x2)
    if (count <= 4) {
      // 把参与者分成两行
      final row1 = participants.take(2).toList();
      final row2 = participants.skip(2).toList();

      return Column(
        children: [
          // 第一行
          Expanded(
            child: Row(
              children: [
                Expanded(child: ParticipantTile(participant: row1[0])),
                const SizedBox(width: 8),
                Expanded(
                  child: row1.length > 1
                      ? ParticipantTile(participant: row1[1])
                      : const Spacer(),
                ), // 如果只有3个人，这里放个占位
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 第二行
          Expanded(
            child: Row(
              children: [
                Expanded(child: ParticipantTile(participant: row2[0])),
                const SizedBox(width: 8),
                Expanded(
                  child: row2.length > 1
                      ? ParticipantTile(participant: row2[1])
                      : const Spacer(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) =>
          ParticipantTile(participant: participants[index]),
    );
  }
}
