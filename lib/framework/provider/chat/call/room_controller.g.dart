// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）

@ProviderFor(RoomController)
final roomControllerProvider = RoomControllerFamily._();

/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）
final class RoomControllerProvider
    extends $AsyncNotifierProvider<RoomController, RoomState> {
  /// 房间控制器
  /// 负责管理 LiveKit 房间的完整生命周期：
  ///   - 连接 / 断开 / 重连
  ///   - 本地媒体（麦克风、摄像头、屏幕共享）
  ///   - 设备切换
  ///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）
  RoomControllerProvider._({
    required RoomControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomControllerHash();

  @override
  String toString() {
    return r'roomControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoomController create() => RoomController();

  @override
  bool operator ==(Object other) {
    return other is RoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomControllerHash() => r'8ee238618e912095c97b93ee87f3e3a26c81ef06';

/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）

final class RoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RoomController,
          AsyncValue<RoomState>,
          RoomState,
          FutureOr<RoomState>,
          String
        > {
  RoomControllerFamily._()
    : super(
        retry: null,
        name: r'roomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 房间控制器
  /// 负责管理 LiveKit 房间的完整生命周期：
  ///   - 连接 / 断开 / 重连
  ///   - 本地媒体（麦克风、摄像头、屏幕共享）
  ///   - 设备切换
  ///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）

  RoomControllerProvider call(String token) =>
      RoomControllerProvider._(argument: token, from: this);

  @override
  String toString() => r'roomControllerProvider';
}

/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）

abstract class _$RoomController extends $AsyncNotifier<RoomState> {
  late final _$args = ref.$arg as String;
  String get token => _$args;

  FutureOr<RoomState> build(String token);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 从服务端获取加入房间的 JWT Token
/// [roomId] 房间 ID

@ProviderFor(roomToken)
final roomTokenProvider = RoomTokenFamily._();

/// 从服务端获取加入房间的 JWT Token
/// [roomId] 房间 ID

final class RoomTokenProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 从服务端获取加入房间的 JWT Token
  /// [roomId] 房间 ID
  RoomTokenProvider._({
    required RoomTokenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomTokenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomTokenHash();

  @override
  String toString() {
    return r'roomTokenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return roomToken(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomTokenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomTokenHash() => r'5ad963ccb1c4096c00486b1c9db4ea3312367c08';

/// 从服务端获取加入房间的 JWT Token
/// [roomId] 房间 ID

final class RoomTokenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  RoomTokenFamily._()
    : super(
        retry: null,
        name: r'roomTokenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 从服务端获取加入房间的 JWT Token
  /// [roomId] 房间 ID

  RoomTokenProvider call(String roomId) =>
      RoomTokenProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomTokenProvider';
}
