import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/domain/RoomState.dart';

part 'LayoutMode.g.dart';

enum LayoutMode {
  grid, // 多人
  focus, // 有人共享屏幕
  carousel, // 1v1
}

@riverpod
LayoutMode layoutMode(Ref ref, RoomState roomState) {
  final participants = <Participant>[
    if (roomState.room.localParticipant != null)
      roomState.room.localParticipant!,
    ...roomState.remoteParticipants,
  ];

  final hasScreenShare = participants.any(
    (p) => p.videoTrackPublications.any((pub) => pub.isScreenShare),
  );
  
  final count = 1 + roomState.remoteParticipants.length;

  if (hasScreenShare) return LayoutMode.focus;
  if (count <= 2) return LayoutMode.carousel;
  return LayoutMode.grid;
}
