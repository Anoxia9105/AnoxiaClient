import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 安装包使用独立连接；移动端挂起时保留文件，前台恢复后安全续传。
class UpdatePackageDownloader with WidgetsBindingObserver {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );
  static const _suspended = 'update download suspended';
  CancelToken? _attemptToken;
  Completer<void>? _foreground;
  bool _disposed = false;
  bool _background = false;
  bool _manualPaused = false;
  void Function(bool)? _onPauseChanged;

  bool get _paused => _background || _manualPaused;

  void pause() {
    _manualPaused = true;
    _publishPause();
  }

  void resume() {
    _manualPaused = false;
    _publishPause();
  }

  void _publishPause() {
    if (_paused) {
      _attemptToken?.cancel(_suspended);
    } else {
      _foreground?.complete();
      _foreground = null;
    }
    _onPauseChanged?.call(_paused);
  }

  UpdatePackageDownloader() {
    WidgetsBinding.instance.addObserver(this);
    _background = _isBackground(WidgetsBinding.instance.lifecycleState);
  }

  bool _isBackground(AppLifecycleState? state) =>
      defaultTargetPlatform == TargetPlatform.android &&
      (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.detached);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _background = false;
    } else if (_isBackground(state)) {
      _background = true;
    }
    _publishPause();
  }

  Future<void> download(
    String url,
    String savePath, {
    required CancelToken cancelToken,
    ProgressCallback? onReceiveProgress,
    void Function(bool)? onPauseChanged,
  }) async {
    _onPauseChanged = onPauseChanged;
    final file = File(savePath);
    // 仅在同一任务内续传，避免把不同版本或上次失败的文件拼在一起。
    await file.parent.create(recursive: true);
    if (await file.exists()) await file.delete();
    String? validator;
    var retries = 0;
    var rangeReset = false;
    while (true) {
      _checkCancelled(cancelToken);
      _onPauseChanged?.call(_paused);
      if (_paused) {
        _foreground ??= Completer<void>();
        await Future.any([
          _foreground!.future,
          cancelToken.whenCancel.then<void>((error) => throw error),
        ]);
        _checkCancelled(cancelToken);
        continue;
      }
      final token = CancelToken();
      _attemptToken = token;
      unawaited(
        cancelToken.whenCancel.then((error) {
          token.cancel(error.error);
        }),
      );
      final offset = validator != null && await file.exists()
          ? await file.length()
          : 0;
      try {
        final response = await _dio.get<ResponseBody>(
          url,
          cancelToken: token,
          options: Options(
            responseType: ResponseType.stream,
            receiveDataWhenStatusError: false,
            validateStatus: (code) => code == 200 || code == 206,
            headers: {
              'Accept-Encoding': 'identity',
              if (offset > 0) 'Range': 'bytes=$offset-',
              if (offset > 0) 'If-Range': validator,
            },
          ),
        );
        final partial = response.statusCode == HttpStatus.partialContent;
        final range = RegExp(
          r'^bytes (\d+)-(\d+)/(\d+)$',
        ).firstMatch(response.headers.value('content-range') ?? '');
        if (partial &&
            (range == null ||
                int.parse(range[1]!) != offset ||
                int.parse(range[2]!) != int.parse(range[3]!) - 1)) {
          await response.data!.stream.listen(null).cancel();
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'invalid update Content-Range',
          );
        }
        final etag = response.headers.value('etag');
        validator = etag != null && !etag.startsWith('W/')
            ? etag
            : response.headers.value('last-modified');
        final start = partial ? offset : 0;
        final total = partial
            ? int.parse(range![3]!)
            : int.tryParse(response.headers.value('content-length') ?? '') ??
                  -1;
        final output = await file.open(
          mode: partial ? FileMode.append : FileMode.write,
        );
        final input = StreamIterator(response.data!.stream);
        // 只注册一次取消回调，避免大安装包每个数据块都积累监听。
        unawaited(token.whenCancel.then((_) => input.cancel()));
        var received = start;
        try {
          while (await input.moveNext()) {
            _checkCancelled(cancelToken);
            await output.writeFrom(input.current);
            received += input.current.length;
            onReceiveProgress?.call(received, total);
          }
          if (token.isCancelled) throw token.cancelError!;
          if (total >= 0 && received != total) {
            throw const HttpException('incomplete update package');
          }
        } finally {
          await input.cancel();
          await output.close();
        }
        _checkCancelled(cancelToken);
        return;
      } catch (error) {
        _checkCancelled(cancelToken);
        // 挂起是暂停，不消耗网络重试次数，也不向 UI 报失败。
        if (token.isCancelled && token.cancelError?.error == _suspended) {
          continue;
        }
        final dioError = error is DioException ? error : null;
        if (dioError?.response?.statusCode == 416 &&
            offset > 0 &&
            !rangeReset) {
          rangeReset = true;
          validator = null;
          continue;
        }
        final code = dioError?.response?.statusCode;
        final retryable =
            error is SocketException ||
            error is HttpException ||
            dioError?.type == DioExceptionType.connectionError ||
            dioError?.type == DioExceptionType.connectionTimeout ||
            dioError?.type == DioExceptionType.receiveTimeout ||
            (dioError?.type == DioExceptionType.unknown &&
                (dioError?.error is SocketException ||
                    dioError?.error is HttpException)) ||
            (code != null && (code == 408 || code == 429 || code >= 500));
        if (!retryable || retries >= 3) rethrow;
        retries++;
        await Future.any([
          Future<void>.delayed(Duration(seconds: retries)),
          cancelToken.whenCancel.then<void>((error) => throw error),
        ]);
      } finally {
        token.cancel('update attempt finished');
        if (identical(_attemptToken, token)) _attemptToken = null;
      }
    }
  }

  void _checkCancelled(CancelToken token) {
    if (token.isCancelled) throw token.cancelError!;
    if (_disposed) {
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(),
        reason: 'downloader disposed',
      );
    }
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _attemptToken?.cancel('downloader disposed');
    _foreground?.complete();
    _foreground = null;
    _dio.close(force: true);
  }
}
