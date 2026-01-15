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
          String message = "网络连接异常";
          if (e.type == DioExceptionType.connectionTimeout) message = "服务器连接超时";
          if (e.type == DioExceptionType.receiveTimeout) message = "接收超时";
          if (e.type == DioExceptionType.sendTimeout) message = "发送超时";
          if (e.type == DioExceptionType.connectionError) message = "无法连接到服务器";
          return handler.next(e);
        },
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  final Dio _dio;

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

  Options _mergeOptions(Options? options, {required bool auth}) {
    final extra = Map<String, dynamic>.from(options?.extra ?? {});
    extra['auth'] = auth;
    return (options ?? Options()).copyWith(extra: extra);
  }
}
