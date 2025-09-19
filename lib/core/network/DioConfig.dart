import 'package:dio/dio.dart';
import 'package:notepadclient/Flavor.dart';

/// DioConfig
/// 用于创建带有基础配置的 Dio 实例
/// 单例模式：全局共享一个 Dio 配置
class DioConfig {
  Dio? _dio;
  // 私有构造
  DioConfig._internal();

  // 静态单例
  static final DioConfig _instance = DioConfig._internal();

  // 工厂构造
  factory DioConfig() => _instance;

  /// 创建基础配置
  BaseOptions createBaseOptions() {
    return BaseOptions(
      baseUrl: FlavorConfig.value.baseUrl, // 从 FlavorConfig 获取环境 API 地址
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    );
  }

  /// 创建 Dio 实例（带日志拦截器）
  Dio createDio() {
    if (_dio != null) return _dio!;
    _dio = Dio(createBaseOptions());
    _dio!.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
    return _dio!;
  }
}
