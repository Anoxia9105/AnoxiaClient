import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间轮播布局组件
///
/// 适用于一对一通话场景：
/// - 远端参与者全屏显示
/// - 本地参与者以小窗形式显示在右下角（画中画模式）
class LayoutRoomCarouselWidget extends StatelessWidget {
  /// 参与者列表
  final List<Participant> participants;

  /// 举手状态映射表（参与者 identity -> 是否举手）
  final Map<String, bool> handRaiseMap;

  /// 静音回调，传入目标参与者 identity
  final void Function(String identity)? onMute;

  /// 踢出回调，传入目标参与者 identity
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
