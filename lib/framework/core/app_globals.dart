import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局 Navigator
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>(
      debugLabel: 'appNavigatorKey',
    );


/// 全局 Riverpod 容器（所有窗口共享，实现状态同步）
///
/// 使用 [UncontrolledProviderScope] 挂载到各个窗口，
/// 确保主窗口、子窗口、更新窗口共享同一套状态。
final ProviderContainer globalContainer = ProviderContainer(
  // 可按需开启观察者，用于调试 Provider 生命周期
  // observers: [
  //   TalkerRiverpodObserver(
  //     talker: log,
  //     settings: const TalkerRiverpodLoggerSettings(printProviderDisposed: true),
  //   ),
  // ],
);