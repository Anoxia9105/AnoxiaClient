import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:anoxia/framework/network/TokenManager.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/main.dart';

import '../logs/talker.dart';
import 'DioConfig.dart';

/// HTTP 客户端封装
///
/// 基于 Dio 封装，提供统一的 RESTful API 调用能力。
/// 支持自动 Token 注入、401 自动登出、文件上传下载等常用功能。
class DioClient {
  /// 单例模式：全局共享一个 DioClient 实例
  DioClient._internal() : _dio = DioConfig().createDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        /// 请求拦截器：注入鉴权 Token
        onRequest: (options, handler) async {
          log.info('Dio request -> ${options.method} ${options.uri}');
          // 默认需要鉴权，除非显式指定 auth=false
          final needAuth = options.extra['auth'] as bool? ?? true;
          if (needAuth) {
            // 优先从内存缓存获取 Token（减少频繁读取本地存储）
            String? token = globalContainer.read(tokenCacheProvider);

            // 内存中没有时，尝试从 TokenManager 恢复（用于冷启动自动登录场景）
            if (token == null || token.isEmpty) {
              token = await TokenManager.instance.getToken();
              if (token != null && token.isNotEmpty) {
                globalContainer.read(tokenCacheProvider.notifier).setToken(token);
              }
            }

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },

        /// 响应拦截器：处理业务状态码
        onResponse: (response, handler) async {
          log.info(response.data);
          if (response.data is Map && response.data.containsKey('code')) {
            final dynamic bizCode = response.data['code'];

            // 401 鉴权失败：触发登出并跳转登录页（排除 logout 接口自身）
            if (bizCode == 401) {
              final requestPath = response.requestOptions.path;
              final isLogoutApi = requestPath.contains('/logout');

              if (!isLogoutApi) {
                unawaited(
                  globalContainer.read(authControllerProvider.notifier).logout(),
                );
                log.info("鉴权失败，已触发登出并跳转登录页");
              }

              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error: "登录过期",
                ),
              );
            }

            // 非 200 状态码：记录错误日志
            if (bizCode != HttpStatus.ok) {
              final String? errorMsg = response.data['msg']?.toString();
              log.error("请求错误: $errorMsg, 业务码: $bizCode");
            }
          }
          return handler.next(response);
        },

        /// 错误拦截器：记录错误信息
        onError: (e, handler) async {
          final uri = e.requestOptions.uri;
          log.error(
            '【onError拦截器】Dio 发生错误 -> uri: $uri, type: ${e.type}, message: ${e.message}, error: ${e.error}',
          );
          return handler.next(e);
        },
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();

  /// 获取单例实例
  factory DioClient() => _instance;

  final Dio _dio;

  /// GET 请求
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// POST 请求
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// PUT 请求
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// DELETE 请求
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// 单文件上传
  ///
  /// [file] 要上传的文件
  /// [fileField] 服务端接收的字段名，默认为 "file"
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// 多文件上传
  ///
  /// [files] 要上传的文件列表
  /// [fileField] 服务端接收的字段名，默认为 "files"
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
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// 文件下载
  ///
  /// [urlPath] 下载路径
  /// [savePath] 本地保存路径
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
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// 合并请求选项
  ///
  /// 将 auth 标志注入到 options.extra 中，供拦截器读取
  Options _mergeOptions(Options? options, {required bool auth}) {
    final extra = Map<String, dynamic>.from(options?.extra ?? {});
    extra['auth'] = auth;
    return (options ?? Options()).copyWith(extra: extra);
  }
}
