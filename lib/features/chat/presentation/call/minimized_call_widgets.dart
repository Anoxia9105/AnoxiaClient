import 'package:anoxia/features/chat/presentation/call/mobile/mobile_call_timer.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/mobile_participant_surface.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 最小化音频通话悬浮窗
class MinimizedAudioCall extends StatelessWidget {
  const MinimizedAudioCall({super.key, required this.title, required this.joinedAt});

  final String title;
  final DateTime? joinedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3245), Color(0xFF171B25)],
        ),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCall02,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                MobileCallTimer(
                  joinedAt: joinedAt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 最小化视频通话悬浮窗
class MinimizedVideoCall extends StatelessWidget {
  const MinimizedVideoCall({super.key, required this.roomState});

  final RoomState? roomState;

  @override
  Widget build(BuildContext context) {
    final Participant? participant =
        roomState?.remoteParticipants.firstOrNull ??
        roomState?.room.localParticipant;
    if (participant == null) {
      return const ColoredBox(
        color: Color(0xFF171A22),
        child: Center(
          child: HugeIcon(icon: HugeIcons.strokeRoundedVideoOff, color: Colors.white54),
        ),
      );
    }
    return MobileParticipantSurface(
      participant: participant,
      compact: true,
      showStatus: false,
      borderRadius: 16,
    );
  }
}