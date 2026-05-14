import 'package:dio/dio.dart';

import '../../common/constants/API.dart';

/// Dio 配置类
///
/// 封装 Dio 的基础配置，包括超时设置、响应类型等。
/// 采用单例模式，确保全局共享同一份配置。
class DioConfig {
  Dio? _dio;

  DioConfig._internal();

  static final DioConfig _instance = DioConfig._internal();

  factory DioConfig() => _instance;

  /// 创建基础配置
  ///
  /// 配置项说明：
  /// - [connectTimeout]：TCP 连接建立超时（从客户端发起到 TCP 握手完成）
  /// - [receiveTimeout]：两次响应数据包之间的最大间隔（非整个请求完成时间）
  /// - [sendTimeout]：数据发送超时（主要用于文件上传场景）
  /// - [validateStatus]：HTTP 状态码校验，< 500 均视为成功
  BaseOptions createBaseOptions() {
    return BaseOptions(
      baseUrl: API.httpBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    );
  }

  /// 创建 Dio 实例
  ///
  /// 带错误处理拦截器，但错误需继续透传，避免请求悬挂
  Dio createDio() {
    if (_dio != null) return _dio!;
    _dio = Dio(createBaseOptions());
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
    return _dio!;
  }
}
