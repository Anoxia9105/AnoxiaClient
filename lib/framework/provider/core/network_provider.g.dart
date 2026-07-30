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

@ProviderFor(networkStatus)
final networkStatusProvider = NetworkStatusProvider._();

/// 网络状态变化流
///
/// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
/// 例如：WiFi 连接、移动数据连接或无网络等状态。

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

String _$networkStatusHash() => r'67227eaca99be5de0ddbf302f8aae89165d83cf4';
