import 'package:dio/dio.dart';
import 'DioConfig.dart';
import '../errors/ApiException.dart';
import 'TokenStorage.dart';

class DioClient {
  // 单例
  DioClient._internal()
      : _dio = DioConfig().createDio(),
        _tokenStorage = TokenStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 默认需要鉴权，除非显式 auth=false
        final needAuth = options.extra['auth'] as bool? ?? true;
        if (needAuth) {
          final token = await _tokenStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        final needAuth = e.requestOptions.extra['auth'] as bool? ?? true;
        final is401 = e.response?.statusCode == 401;
        final isRefreshPath = e.requestOptions.path == '/auth/refresh';

        // 匿名请求或刷新接口本身，不参与自动刷新
        if (!needAuth || !is401 || isRefreshPath) {
          return handler.next(e);
        }

        final refreshToken = await _tokenStorage.readRefreshToken();
        if (refreshToken == null) {
          return handler.next(e);
        }

        return await _handle401Error(e, handler, refreshToken);
      },
    ));
  }

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;
  final List<Future<void> Function()> _retryQueue = [];

  Future<void> _handle401Error(
      DioException err, ErrorInterceptorHandler handler, String refreshToken) async {
    if (_isRefreshing) {
      // 等待刷新完成后重试该请求
      _retryQueue.add(() async {
        final token = await _tokenStorage.readAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final cloneRes = await _dio.fetch(
          err.requestOptions.copyWith(cancelToken: err.requestOptions.cancelToken),
        );
        handler.resolve(cloneRes);
      });
      return;
    }

    _isRefreshing = true;
    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'auth': false}), // 刷新接口必须匿名
      );

      final newAccessToken = res.data['access_token'];
      final newRefreshToken = res.data['refresh_token'];

      await _tokenStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _tokenStorage.saveRefreshToken(newRefreshToken);
      }

      // 先清空队列，避免重入
      final tasks = List.of(_retryQueue);
      _retryQueue.clear();
      for (final retry in tasks) {
        await retry();
      }

      // 重试当前请求
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final cloneRes = await _dio.fetch(
        err.requestOptions.copyWith(cancelToken: err.requestOptions.cancelToken),
      );
      handler.resolve(cloneRes);
    } catch (_) {
      await _tokenStorage.clear();
      handler.reject(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // 统一封装：新增 auth 参数，默认 true；匿名传 false
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, auth: auth),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: _mergeOptions(options, auth: auth),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: _mergeOptions(options, auth: auth),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        options: _mergeOptions(options, auth: auth),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

  Options _mergeOptions(Options? options, {required bool auth}) {
    final extra = Map<String, dynamic>.from(options?.extra ?? {});
    extra['auth'] = auth;
    return (options ?? Options()).copyWith(extra: extra);
  }
}
