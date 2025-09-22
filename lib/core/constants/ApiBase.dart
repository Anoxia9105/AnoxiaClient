
abstract class ApiBase {

  String pathSocket(String token) => '/chat?token=$token';


  String pathCaptchaImage() => '/captchaImage';
  String pathLogin() => '/login';
  String pathGetInfo()=>'/getInfo';
  String pathRefreshToken()=>'/refresh';
  String pathLogout()=>'/logout';

  // 可选：通用请求方法
  // Future<Response> get(String path) => DioClient().get(path);
}
