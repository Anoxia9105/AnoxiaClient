import 'dart:io';

import 'package:dio/dio.dart';
import 'package:anoxia/framework/network/TokenManager.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/main.dart';

import '../logs/talker.dart';
import 'DioConfig.dart';

class DioClient {
  // 单例
  DioClient._internal() : _dio = DioConfig().createDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 请求拦截器：添加鉴权 token
        onRequest: (options, handler) async {
          log.info('Dio request -> ${options.method} ${options.uri}');
          // 默认需要鉴权，除非显式 auth=false
          final needAuth = options.extra['auth'] as bool? ?? true;
          if (needAuth) {
            final token = await TokenManager.instance.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // log.info(response.data);
          if (response.data is Map && response.data.containsKey('code')) {
            final dynamic bizCode = response.data['code'];

            if (bizCode == 401) {
              // 鉴权失败，跳转登录
              globalContainer.read(authControllerProvider.notifier).logout();
              log.info("鉴权失败，已清除 token 并跳转登录页");
              // return handler.reject(
              //   DioException(
              //     requestOptions: response.requestOptions,
              //     error: "登录过期",
              //   ),
              // );
              return;
            }
            if (bizCode != HttpStatus.ok) {
              final String? errorMsg = response.data['msg']?.toString();
              //记录日志
              log.error("请求错误: $errorMsg, 业务码: $bizCode");
            }
          }
          return handler.next(response);
        },
        onError: (e, handler) async {
          final uri = e.requestOptions.uri;
          log.error(
            '【onError拦截器】Dio 发生错误 -> uri: $uri, type: ${e.type}, message: ${e.message}, error: ${e.error}',
          );
          if (e.type == DioExceptionType.connectionTimeout)
            if (e.type == DioExceptionType.receiveTimeout)
              if (e.type == DioExceptionType.sendTimeout)
                if (e.type == DioExceptionType.connectionError)
                  return handler.next(e);
        },
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  final Dio _dio;

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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  /// 上传文件（支持单文件）
  Future<Response> uploadFile(
    String path, {
    required File file,
    String fileField = "file",
    Map<String, dynamic>? data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(file.path, filename: fileName),
        if (data != null) ...data,
      });

      return await _dio.post(
        path,
        data: formData,
        options: _mergeOptions(
          options?.copyWith(contentType: 'multipart/form-data'),
          auth: auth,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// 多文件上传（支持 files: List<File>）
  Future<Response> uploadFiles(
    String path, {
    required List<File> files,
    String fileField = "files",
    Map<String, dynamic>? data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final List<MultipartFile> multipartFiles = [];

      for (final file in files) {
        final fileName = file.path.split('/').last;
        multipartFiles.add(
          await MultipartFile.fromFile(file.path, filename: fileName),
        );
      }

      final formData = FormData.fromMap({
        fileField: multipartFiles,
        if (data != null) ...data,
      });

      return await _dio.post(
        path,
        data: formData,
        options: _mergeOptions(
          options?.copyWith(contentType: 'multipart/form-data'),
          auth: auth,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: _mergeOptions(
          options,
          auth: false,
        ), // Updates usually don't need auth
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Options _mergeOptions(Options? options, {required bool auth}) {
    final extra = Map<String, dynamic>.from(options?.extra ?? {});
    extra['auth'] = auth;
    return (options ?? Options()).copyWith(extra: extra);
  }
}
