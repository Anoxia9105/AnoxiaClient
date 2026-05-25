import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

@riverpod
Stream<List<ConnectivityResult>> networkStatus(Ref ref) {
  return Connectivity().onConnectivityChanged;
}