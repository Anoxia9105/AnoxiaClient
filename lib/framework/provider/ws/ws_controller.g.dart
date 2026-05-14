// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。

@ProviderFor(WsController)
const wsControllerProvider = WsControllerProvider._();

/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。
final class WsControllerProvider
    extends $NotifierProvider<WsController, WsState> {
  /// WebSocket 连接控制器
  ///
  /// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
  /// 采用 keepAlive 模式，确保全局只有一个连接实例。
  const WsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wsControllerHash();

  @$internal
  @override
  WsController create() => WsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WsState>(value),
    );
  }
}

String _$wsControllerHash() => r'c248c1e3293c81c077c09543f88be3cdc2372d71';

/// WebSocket 连接控制器
///
/// 负责 WebSocket 连接的建立、心跳维护、自动重连和消息分发。
/// 采用 keepAlive 模式，确保全局只有一个连接实例。

abstract class _$WsController extends $Notifier<WsState> {
  WsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<WsState, WsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WsState, WsState>,
              WsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息

@ProviderFor(wsMessageStream)
const wsMessageStreamProvider = WsMessageStreamProvider._();

/// WebSocket 消息流 Provider
///
/// 供其他 Provider 监听 WebSocket 消息

final class WsMessageStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<PacketFrame<IPacket>>,
          PacketFrame<IPacket>,
          Stream<PacketFrame<IPacket>>
        >
    with
        $FutureModifier<PacketFrame<IPacket>>,
        $StreamProvider<PacketFrame<IPacket>> {
  /// WebSocket 消息流 Provider
  ///
  /// 供其他 Provider 监听 WebSocket 消息
  const WsMessageStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wsMessageStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wsMessageStreamHash();

  @$internal
  @override
  $StreamProviderElement<PacketFrame<IPacket>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PacketFrame<IPacket>> create(Ref ref) {
    return wsMessageStream(ref);
  }
}

String _$wsMessageStreamHash() => r'2f7b7b5c7c4429f0fe9d68c8412729aa7eed8a78';
