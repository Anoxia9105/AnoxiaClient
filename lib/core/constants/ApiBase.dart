import 'dart:io';

import 'package:dio/dio.dart';
import 'package:notepadclient/core/network/DioClient.dart';

abstract class ApiBase {
  //匿名接口
  String pathCaptchaImage() => '/captchaImage';

  String pathLogin() => '/login';

  String pathLogout() => '/logout';

  //登录用户接口
  String pathGetInfo() => '/getInfo';

  //刷新token
  String pathRefreshToken() => '/refresh';

  String pathSocket(String token) => '/chat?token=$token';

  //聊天室接口
  String pathRoomList() => '/chat/getRoomList';

  String pathRoomMessage() => '/chat/getRoomMessage';

  //联系人接口
  String pathContactList() => '/contact/list';
  String pathContactRequestList() => '/contact/request';

  //通用请求方法
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool auth = true,
  }) => DioClient().get(path, queryParameters: queryParameters, auth: auth);

  Future<Response> post(String path, {dynamic data, bool auth = true}) =>
      DioClient().post(path, data: data, auth: auth);

  Future<T> handleResponse<T>(
    Future<Response> futureResponse, {
    required T Function(dynamic data) parser,
    required T defaultValue,
  }) async {
    final response = await futureResponse;

    // 1. 判空和状态码校验
    if (response.statusCode != HttpStatus.ok || response.data == null) {
      return defaultValue;
    }

    final data = response.data;

    // 2. 通用业务校验
    if (data["code"] != HttpStatus.ok || data["data"] == null) {
      return defaultValue;
    }

    // 3. 数据解析（交给调用方决定怎么解析）
    return parser(data["data"]);
  }
}
