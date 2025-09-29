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

  //通用请求方法
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool auth = true,
  }) => DioClient().get(path,queryParameters: queryParameters,auth: auth);
  Future<Response> post(
    String path, {
    dynamic data,
    bool auth = true,
  }) => DioClient().post(path,data: data,auth: auth);
}
