import 'package:anoxia/features/chat/presentation/call/mobile/mobile_call_timer.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: Theme.of(context).extension<AppColors>()?.scaffoldGradient,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCall02,
                color: cs.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                MobileCallTimer(
                  joinedAt: joinedAt,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
      final cs = Theme.of(context).colorScheme;
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedVideoOff,
            color: cs.onSurfaceVariant,
            size: 22,
          ),
        ),
      );
    }
    return MobileParticipantSurface(
      participant: participant,
      compact: true,
      showStatus: false,
      borderRadius: 12,
    );
  }
}
