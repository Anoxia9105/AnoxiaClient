// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 网络状态变化流
///
/// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
/// 例如：WiFi 连接、移动数据连接或无网络等状态。
///
/// 先下发一次当前状态（部分平台如 Web/WASM 的变更流可能长时间不发射，
/// 导致 UI 一直停留在「连接中」），再订阅后续变更。
/// 初始探测失败时静默跳过，由调用方按 WS 状态回退展示。

@ProviderFor(networkStatus)
final networkStatusProvider = NetworkStatusProvider._();

/// 网络状态变化流
///
/// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
/// 例如：WiFi 连接、移动数据连接或无网络等状态。
///
/// 先下发一次当前状态（部分平台如 Web/WASM 的变更流可能长时间不发射，
/// 导致 UI 一直停留在「连接中」），再订阅后续变更。
/// 初始探测失败时静默跳过，由调用方按 WS 状态回退展示。

final class NetworkStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConnectivityResult>>,
          List<ConnectivityResult>,
          Stream<List<ConnectivityResult>>
        >
    with
        $FutureModifier<List<ConnectivityResult>>,
        $StreamProvider<List<ConnectivityResult>> {
  /// 网络状态变化流
  ///
  /// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
  /// 例如：WiFi 连接、移动数据连接或无网络等状态。
  ///
  /// 先下发一次当前状态（部分平台如 Web/WASM 的变更流可能长时间不发射，
  /// 导致 UI 一直停留在「连接中」），再订阅后续变更。
  /// 初始探测失败时静默跳过，由调用方按 WS 状态回退展示。
  NetworkStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkStatusHash();

  @$internal
  @override
  $StreamProviderElement<List<ConnectivityResult>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConnectivityResult>> create(Ref ref) {
    return networkStatus(ref);
  }
}

String _$networkStatusHash() => r'520ba179c23fdfd129679a471ca7a404c64d316a';
