import 'package:dio/dio.dart';

import '../../common/constants/API.dart';

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
      baseUrl: API.httpBaseUrl,
      // 1. 连接超时：指从客户端发起连接到建立 TCP 连接的时间
      connectTimeout: const Duration(seconds: 20),

      // 2. 接收超时：指两次响应数据包之间的时间间隔（不是整个请求完成的时间）
      receiveTimeout: const Duration(seconds: 30),

      // 3. 发送超时：指将数据发送到服务器的时间（通常用于文件上传）
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
      // 强制期望返回 JSON
      validateStatus: (status) => status != null && status < 500,
    );
  }

  /// 创建 Dio 实例（带日志拦截器）
  Dio createDio() {
    if (_dio != null) return _dio!;
    _dio = Dio(createBaseOptions());
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // 可以在这里统一处理一些非业务错，但必须继续透传，避免请求悬挂
          return handler.next(e);
        },
      ),
    );
    return _dio!;
  }
}
