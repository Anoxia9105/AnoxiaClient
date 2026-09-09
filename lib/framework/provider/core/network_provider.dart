// 网络状态监听 Provider
//
// 提供网络连接状态变化流，供 UI 层监听网络状态变化。
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

/// 网络状态变化流
///
/// 监听设备网络连接状态的变化，返回 [ConnectivityResult] 列表。
/// 例如：WiFi 连接、移动数据连接或无网络等状态。
///
/// 先下发一次当前状态（部分平台如 Web/WASM 的变更流可能长时间不发射，
/// 导致 UI 一直停留在「连接中」），再订阅后续变更。
/// 初始探测失败时静默跳过，由调用方按 WS 状态回退展示。
@riverpod
Stream<List<ConnectivityResult>> networkStatus(Ref ref) async* {
  try {
    yield await Connectivity()
        .checkConnectivity()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // 忽略：后续变更流仍会下发状态
  }
  yield* Connectivity().onConnectivityChanged;
}