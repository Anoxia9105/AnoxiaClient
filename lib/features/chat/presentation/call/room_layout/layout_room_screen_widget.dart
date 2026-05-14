import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

class LayoutRoomScreenWidget extends StatefulWidget {
  final Participant screenParticipant;
  final List<Participant> otherParticipants;
  final Map<String, bool> handRaiseMap;
  final void Function(String identity)? onMute;
  final void Function(String identity)? onKick;

  const LayoutRoomScreenWidget({
    super.key,
    required this.screenParticipant,
    required this.otherParticipants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
  });

  @override
  State<LayoutRoomScreenWidget> createState() => _LayoutRoomScreenWidgetState();
}

class _LayoutRoomScreenWidgetState extends State<LayoutRoomScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧：大屏显示共享内容
        Expanded(
          flex: 3,
          child: ParticipantTile(
            participant: widget.screenParticipant,
            handRaised:
                widget.handRaiseMap[widget.screenParticipant.identity] == true,
            onMute: widget.onMute,
            onKick: widget.onKick,
            key: ValueKey('${widget.screenParticipant.sid}-screen'),
          ),
        ),

        const SizedBox(width: 8),

        // 右侧：小列表显示其他参与者
        if (widget.otherParticipants.isNotEmpty)
          SizedBox(
            width: 40.w,
            child: ListView.separated(
              itemCount: widget.otherParticipants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = widget.otherParticipants[index];
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: ParticipantTile(
                    participant: p,
                    handRaised: widget.handRaiseMap[p.identity] == true,
                    onMute: widget.onMute,
                    onKick: widget.onKick,
                    key: ValueKey(p.sid),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
