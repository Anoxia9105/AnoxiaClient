import 'dart:typed_data';

import '../../framework/domain/app_background.dart';

abstract interface class AppBackgroundRepository {
  Future<AppBackgroundState> fetch();

  Future<AppBackgroundState> upload({
    required Uint8List bytes,
    required String fileName,
  });

  Future<AppBackgroundState> updatePreference({
    required int? activeAssetId,
    required double surfaceOpacity,
  });

  Future<AppBackgroundState> delete(int assetId);
}
