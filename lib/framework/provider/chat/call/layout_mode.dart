// 通话布局模式
//
// 根据通话参与者数量和屏幕共享状态，自动计算适合的 UI 布局模式。
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/domain/room_state.dart';

part 'layout_mode.g.dart';

/// 通话布局模式枚举
enum LayoutMode {
  /// 多人网格布局（1v1 与多人统一使用）
  grid,

  /// 屏幕共享焦点布局（有人共享屏幕时）
  focus,

  /// 1v1 轮播布局（历史保留：远端全屏 + 本地画中画）
  ///
  /// 现已不再使用，[layoutMode] 对 1v1 直接返回 [LayoutMode.grid]，
  /// 保留该枚举值仅为兼容旧的持久化/调用方，渲染层会将其降级为网格。
  @Deprecated('1v1 已统一使用网格布局，该值不再产生，仅做兼容降级为 grid')
  carousel,
}

/// 通话布局模式 Provider
///
/// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
/// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。
@riverpod
LayoutMode layoutMode(Ref ref, RoomState roomState) {
  final participants = <Participant>[
    if (roomState.room.localParticipant != null)
      roomState.room.localParticipant!,
    ...roomState.remoteParticipants,
  ];

  final hasScreenShare = participants.any(
    (p) => p.videoTrackPublications.any(
      // 仅活跃的共享轨道才算共享中：已静音/未订阅（远端尚未收到/已停止但
      // publication 残留）必须视为无共享，否则纯头像也会被误判进焦点布局。
      (pub) => pub.isScreenShare && !pub.muted && pub.subscribed,
    ),
  );

  if (hasScreenShare) return LayoutMode.focus;
  return LayoutMode.grid;
}
