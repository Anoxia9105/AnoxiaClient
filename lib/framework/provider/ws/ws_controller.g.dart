// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WsController)
const wsControllerProvider = WsControllerProvider._();

final class WsControllerProvider
    extends $NotifierProvider<WsController, WsState> {
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

String _$wsControllerHash() => r'b6d3b1187889526da62a78785cf690509a6815db';

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

@ProviderFor(wsMessageStream)
const wsMessageStreamProvider = WsMessageStreamProvider._();

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

String _$wsMessageStreamHash() => r'0cf9ebce70acee04fc3dca65366ce81a7f825bfe';
