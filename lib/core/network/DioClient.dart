import 'dart:io';

import 'package:dio/dio.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';
import 'package:notepadclient/core/network/TokenManager.dart';
import 'package:notepadclient/core/utils/SSUtil.dart';
import 'package:notepadclient/shared/widgets/Toast.dart';

import '../errors/ApiException.dart';
import 'DioConfig.dart';

class DioClient {
  // 单例
  DioClient._internal() : _dio = DioConfig().createDio(){
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
          final dynamic bizCode = response.data['code'];
          if(bizCode != HttpStatus.ok){
            final String? errorMsg = response.data['msg']?.toString();
            //弹窗
            Toast.showToast(errorMsg ?? '请求错误 code：$bizCode',type: ToastType.error);
          }
          return handler.next(response);
        },
        onError: (e, handler) async {
          Toast.showToast("服务器异常,请稍后再试",type: ToastType.error);
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
      throw ApiException(
        e.message ?? 'Network error',
        code: e.response?.statusCode,
      );
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
      throw ApiException(
        e.message ?? 'Network error',
        code: e.response?.statusCode,
      );
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
      throw ApiException(
        e.message ?? 'Network error',
        code: e.response?.statusCode,
      );
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
      throw ApiException(
        e.message ?? 'Network error',
        code: e.response?.statusCode,
      );
    }
  }

  Options _mergeOptions(Options? options, {required bool auth}) {
    final extra = Map<String, dynamic>.from(options?.extra ?? {});
    extra['auth'] = auth;
    return (options ?? Options()).copyWith(extra: extra);
  }
}
