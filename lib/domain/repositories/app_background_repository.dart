import 'dart:typed_data';

import '../../framework/domain/app_background.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

class AppBackgroundException implements Exception {
  final String message;
  final bool isLocalizationKey;

  const AppBackgroundException(this.message) : isLocalizationKey = false;

  const AppBackgroundException.localized(this.message)
    : isLocalizationKey = true;

  @override
  String toString() => message;
}

abstract interface class AppBackgroundRepository {
  Future<AppBackgroundState> fetch();

  Future<AppBackgroundState> upload({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  });

  Future<AppBackgroundState> updatePreference({
    required int? activeAssetId,
    required double surfaceOpacity,
  });

  Future<AppBackgroundState> delete(int assetId);
}
