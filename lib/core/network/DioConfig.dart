import 'package:dio/dio.dart';
import '../constants/env.dart';

class DioConfig {
  static BaseOptions createBaseOptions() {
    return BaseOptions(
      // baseUrl: ,
      connectTimeout: Duration(seconds: Env.timeoutSeconds),
      receiveTimeout: Duration(seconds: Env.timeoutSeconds),
      headers: {'Accept': 'application/json'},
    );
  }

  static Dio createDio() {
    final dio = Dio(createBaseOptions());
    // 可在此添加全局拦截器（日志等）
    return dio;
  }
}
