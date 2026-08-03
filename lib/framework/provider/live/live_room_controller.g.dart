// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 直播房间控制器
///
/// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
/// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。

@ProviderFor(LiveRoomController)
final liveRoomControllerProvider = LiveRoomControllerFamily._();

/// 直播房间控制器
///
/// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
/// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。
final class LiveRoomControllerProvider
    extends $AsyncNotifierProvider<LiveRoomController, RoomState> {
  /// 直播房间控制器
  ///
  /// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
  /// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。
  LiveRoomControllerProvider._({
    required LiveRoomControllerFamily super.from,
    required (String, bool) super.argument,
  }) : super(
         retry: null,
         name: r'liveRoomControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveRoomControllerHash();

  @override
  String toString() {
    return r'liveRoomControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  LiveRoomController create() => LiveRoomController();

  @override
  bool operator ==(Object other) {
    return other is LiveRoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveRoomControllerHash() =>
    r'9a3f552b4c964feb5b58d97b7829873bed675249';

/// 直播房间控制器
///
/// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
/// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。

final class LiveRoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LiveRoomController,
          AsyncValue<RoomState>,
          RoomState,
          FutureOr<RoomState>,
          (String, bool)
        > {
  LiveRoomControllerFamily._()
    : super(
        retry: null,
        name: r'liveRoomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 直播房间控制器
  ///
  /// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
  /// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。

  LiveRoomControllerProvider call(String roomId, bool isHost) =>
      LiveRoomControllerProvider._(argument: (roomId, isHost), from: this);

  @override
  String toString() => r'liveRoomControllerProvider';
}

/// 直播房间控制器
///
/// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
/// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。

abstract class _$LiveRoomController extends $AsyncNotifier<RoomState> {
  late final _$args = ref.$arg as (String, bool);
  String get roomId => _$args.$1;
  bool get isHost => _$args.$2;

  FutureOr<RoomState> build(String roomId, bool isHost);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RoomState>, RoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RoomState>, RoomState>,
              AsyncValue<RoomState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
