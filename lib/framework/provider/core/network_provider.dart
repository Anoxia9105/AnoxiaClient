// 网络状态监听 Provider
//
// 提供网络连接状态变化流，供 UI 层监听网络状态变化。
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

/// 网络状态变化流
///
/// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
/// 例如：WiFi 连接、移动数据连接或无网络等状态。
@riverpod
Stream<List<ConnectivityResult>> networkStatus(Ref ref) {
  return Connectivity().onConnectivityChanged;
}