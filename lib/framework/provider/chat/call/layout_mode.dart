/// 通话布局模式
///
/// 根据通话参与者数量和屏幕共享状态，自动计算适合的 UI 布局模式。
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/domain/room_state.dart';

part 'layout_mode.g.dart';

/// 通话布局模式枚举
enum LayoutMode {
  /// 多人网格布局
  grid,

  /// 屏幕共享焦点布局（有人共享屏幕时）
  focus,

  /// 1v1 轮播布局
  carousel,
}

/// 通话布局模式 Provider
///
/// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
/// 规则：有屏幕共享 → 焦点模式；参与者 ≤2 → 轮播模式；其余 → 网格模式。
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
