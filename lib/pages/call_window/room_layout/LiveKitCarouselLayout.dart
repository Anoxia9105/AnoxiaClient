import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../framework/provider/kit/room_controller.dart';
import '../component/ParticipantTile.dart';

/// 轮播布局模式 - 主屏幕显示一个参与者，底部/侧边显示其他参与者缩略图
class LiveKitCarouselLayout extends StatelessWidget {
  const LiveKitCarouselLayout({
    super.key,
    required this.token,
    this.focusedParticipant,
    this.onParticipantTap,
  });

  final String token;
  final Participant? focusedParticipant;
  final void Function(Participant)? onParticipantTap;

  @override
  Widget build(BuildContext context) {
    final roomState = roomControllerProvider(token);
    final state = roomState.value;
    if (state == null) return SizedBox.shrink();

    final participants = _getParticipants(state);
    if (participants.isEmpty) return SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    final focused = focusedParticipant ?? participants.first;
    final others = participants.where((p) => p.sid != focused.sid).toList();

    if (isMobile && isPortrait) {
      return _buildMobilePortrait(focused, others);
    } else {
      return _buildDesktopOrLandscape(focused, others);
    }
  }

  Widget _buildMobilePortrait(Participant focused, List<Participant> others) {
    return Column(
      children: [
        Expanded(
          child: ParticipantTile(
            participant: focused,
            token: token,
          ),
        ),
        if (others.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(8),
              itemCount: others.length,
              itemBuilder: (context, index) {
                final participant = others[index];
                return GestureDetector(
                  onTap: () => onParticipantTap?.call(participant),
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    child: ParticipantTile(
                      participant: participant,
                      token: token,
                      compact: true,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopOrLandscape(Participant focused, List<Participant> others) {
    return Row(
      children: [
        if (others.isNotEmpty)
          SizedBox(
            width: 160,
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: others.length,
              itemBuilder: (context, index) {
                final participant = others[index];
                return GestureDetector(
                  onTap: () => onParticipantTap?.call(participant),
                  child: Container(
                    height: 100,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ParticipantTile(
                      participant: participant,
                      token: token,
                      compact: true,
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: ParticipantTile(
            participant: focused,
            token: token,
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
