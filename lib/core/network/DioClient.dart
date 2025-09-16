import 'package:dio/dio.dart';
import 'DioConfig.dart';
import '../errors/ApiException.dart';
import '../constants/StorageKeys.dart';
import 'TokenStorage.dart';

class DioClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  DioClient(this._dio, this._tokenStorage) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        // 简单示例：401 -> 可触发刷新 token 的逻辑
        if (e.response?.statusCode == 401) {
          // TODO: refresh token logic
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return res;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return res;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error', code: e.response?.statusCode);
    }
  }

// put, delete ... 同理
}
