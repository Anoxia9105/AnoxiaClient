import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'local_data_source.dart';
import 'remote_data_source.dart';
import 'sync_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSource(ref.watch(appDatabaseProvider));
});

final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return RemoteDataSource();
});

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
