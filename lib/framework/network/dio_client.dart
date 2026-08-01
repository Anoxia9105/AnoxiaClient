import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/network/token_manager.dart';

import '../logs/talker.dart';
import 'dio_config.dart';

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
          // 确保 Content-Type 被正确设置
          options.contentType = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept-Language'] = _acceptLanguage;
          log.info('Dio request headers -> ${options.headers}');
          log.info('Dio request data -> ${options.data}');
          // 默认需要鉴权，除非显式指定 auth=false
          final needAuth = options.extra['auth'] as bool? ?? true;
          if (needAuth) {
            // 优先从内存缓存获取 Token（减少频繁读取本地存储）
            final token = await _tokenLoader();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },

        /// 响应拦截器：处理业务状态码
        onResponse: (response, handler) async {
          // log.info(response.data);
          if (response.data is Map && response.data.containsKey('code')) {
            final dynamic bizCode = response.data['code'];
            final needAuth =
                response.requestOptions.extra['auth'] as bool? ?? true;
            final skipAuthFailureLogout =
                response.requestOptions.extra['skipAuthFailureLogout']
                    as bool? ??
                false;

            // 401 鉴权失败：触发登出并跳转登录页（排除 logout 接口自身）
            if (bizCode == 401) {
              final requestPath = response.requestOptions.path;
              final isLogoutApi = requestPath.contains('/logout');

              if (needAuth && !skipAuthFailureLogout && !isLogoutApi) {
                final handler = _onUnauthorized;
                if (handler != null && !_isUnauthorizedHandling) {
                  _isUnauthorizedHandling = true;
                  unawaited(
                    handler().whenComplete(() => _isUnauthorizedHandling = false),
                  );
                  log.info('鉴权失败，已触发登出并跳转登录页');
                }
              }

              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error: 'api_login_expired'.tr(),
                ),
              );
            }

            // 非 200 状态码：记录错误日志
            if (bizCode != 200) {
              final String? errorMsg = response.data['msg']?.toString();
              log.error('请求错误: $errorMsg, 业务码: $bizCode');
            }
          }
          return handler.next(response);
        },

        /// 错误拦截器：记录错误信息
        onError: (e, handler) async {
          final uri = e.requestOptions.uri;
          if (CancelToken.isCancel(e)) {
            log.info('Dio 请求已取消 -> uri: $uri, reason: ${e.error}');
          } else {
            log.error(
              '【onError拦截器】Dio 发生错误 -> uri: $uri, type: ${e.type}, message: ${e.message}, error: ${e.error}',
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();

  /// 获取单例实例
  factory DioClient() => _instance;

  final Dio _dio;
  Future<String?> Function() _tokenLoader = TokenManager.instance.getToken;
  Future<void> Function()? _onUnauthorized;
  String _acceptLanguage = 'zh-CN';

  /// 防止 401 响应触发递归登出（如 ContactList 在登出过程中又发起请求导致 401）
  bool _isUnauthorizedHandling = false;

  void configureAuth({
    required Future<String?> Function() tokenLoader,
    required Future<void> Function() onUnauthorized,
  }) {
    _tokenLoader = tokenLoader;
    _onUnauthorized = onUnauthorized;
  }

  /// 设置 Accept-Language 请求头，用于后端国际化
  void setLocale(String locale) {
    _acceptLanguage = locale;
  }

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
  /// [file] 要上传的文件（全平台兼容，Web 端使用 XFile.fromData 传 bytes）
  /// [fileField] 服务端接收的字段名，默认为 "file"
  Future<Response> uploadFile(
    String path, {
    required XFile file,
    String fileField = 'file',
    Map<String, dynamic>? data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileField: MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        ),
        ...?data,
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
  /// [files] 要上传的文件列表（全平台兼容，Web 端使用 XFile.fromData 传 bytes）
  /// [fileField] 服务端接收的字段名，默认为 "files"
  Future<Response> uploadFiles(
    String path, {
    required List<XFile> files,
    String fileField = 'files',
    Map<String, dynamic>? data,
    bool auth = true,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final multipartFiles = <MultipartFile>[];

      for (final file in files) {
        multipartFiles.add(
          MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          ),
        );
      }

      final formData = FormData.fromMap({fileField: multipartFiles, ...?data});

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
        options: _mergeOptions(options, auth: false),
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
    return (options ?? Options()).copyWith(
      extra: extra,
      contentType: 'application/json',
    );
  }
}
