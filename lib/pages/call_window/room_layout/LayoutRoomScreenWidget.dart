import 'package:anoxia/pages/call_window/component/ParticipantTile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart' show Participant;

class LayoutRoomScreenWidget extends StatefulWidget {
  final Participant screenParticipant;
  final List<Participant> otherParticipants;
  const LayoutRoomScreenWidget({
    super.key,
    required this.screenParticipant,
    required this.otherParticipants,
  });

  @override
  State<LayoutRoomScreenWidget> createState() => _LayoutRoomScreenWidgetState();
}

class _LayoutRoomScreenWidgetState extends State<LayoutRoomScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧：大屏幕显示共享内容
        Expanded(
          flex: 3, // 占据 3/4 的宽度
          child: ParticipantTile(
            participant: widget.screenParticipant,
            key: ValueKey('${widget.screenParticipant.sid}-screen'),
          ),
        ),

        const SizedBox(width: 8),

        // 右侧：小列表显示其他参与者
        if (widget.otherParticipants.isNotEmpty)
          SizedBox(
            width: 80.w,
            child: ListView.separated(
              itemCount: widget.otherParticipants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: ParticipantTile(
                    participant: widget.otherParticipants[index],
                    key: ValueKey(widget.otherParticipants[index].sid),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
