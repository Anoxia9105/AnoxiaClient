import 'package:dio/dio.dart';

class UpdatePackageDownloader {
  Future<void> download(
    String url,
    String savePath, {
    required CancelToken cancelToken,
    ProgressCallback? onReceiveProgress,
    void Function(bool)? onPauseChanged,
  }) async {
    throw UnsupportedError('update download is not supported on web');
  }

  void pause() {}
  void resume() {}
  void dispose() {}
}
