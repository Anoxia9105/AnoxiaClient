import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../framework/provider/kit/room_controller.dart';
import '../component/ParticipantTile.dart';

/// 焦点模式 - 选中的参与者显示在主屏幕，其他人在缩略图中显示
class LiveKitFocusLayout extends StatelessWidget {
  const LiveKitFocusLayout({
    super.key,
    required this.token,
    required this.focusedParticipant,
    this.onUnfocus,
  });

  final String token;
  final Participant focusedParticipant;
  final VoidCallback? onUnfocus;

  @override
  Widget build(BuildContext context) {
    final roomState = roomControllerProvider(token);
    final state = roomState.value;
    if (state == null) return SizedBox.shrink();

    final participants = _getParticipants(state);
    final others = participants.where((p) => p.sid != focusedParticipant.sid).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    if (isMobile && isPortrait) {
      return _buildMobilePortrait(others);
    } else {
      return _buildDesktop(others);
    }
  }

  Widget _buildMobilePortrait(List<Participant> others) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ParticipantTile(
                participant: focusedParticipant,
                token: token,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: onUnfocus,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (others.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(8),
              itemCount: others.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 60,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: ParticipantTile(
                    participant: others[index],
                    token: token,
                    compact: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDesktop(List<Participant> others) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              ParticipantTile(
                participant: focusedParticipant,
                token: token,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: onUnfocus,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (others.isNotEmpty)
          Container(
            width: 140,
            color: Colors.black87,
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: others.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 90,
                  margin: EdgeInsets.only(bottom: 8),
                  child: ParticipantTile(
                    participant: others[index],
                    token: token,
                    compact: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<Participant> _getParticipants(AsyncValue<RoomState> roomState) {
    final state = roomState.value;
    if (state == null) return [];

    final participants = <Participant>[];
    if (state.room.localParticipant != null) {
      participants.add(state.room.localParticipant!);
    }
    participants.addAll(state.remoteParticipants);
    return participants;
  }
}
