// 本地缓存 Provider 注册
//
// 定义 AppDatabase、LocalDataSource、RemoteDataSource 和 SyncRepository
// 的 Riverpod Provider，并监听网络状态以自动触发同步恢复。
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'local_data_source.dart';
import 'remote_data_source.dart';
import 'sync_repository.dart';

/// 应用数据库 Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 本地数据源 Provider
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSource(ref.watch(appDatabaseProvider));
});

/// 远程数据源 Provider
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return RemoteDataSource();
});

/// 同步仓库 Provider
///
/// 组合本地和远程数据源，并在网络恢复时自动触发同步操作。
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final repository = SyncRepository(
    local: ref.watch(localDataSourceProvider),
    remote: ref.watch(remoteDataSourceProvider),
  );

  var wasOffline = false;
  final subscription = Connectivity().onConnectivityChanged.listen((result) {
    final isOnline = !result.contains(ConnectivityResult.none);
    if (wasOffline && isOnline) {
      unawaited(repository.onNetworkRecovered());
    }
    wasOffline = !isOnline;
  });
  ref.onDispose(subscription.cancel);

  return repository;
});
