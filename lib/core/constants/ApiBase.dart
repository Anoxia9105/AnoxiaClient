abstract class ApiBase {

  String pathCaptchaImage() => '/captchaImage';
  String pathLogin() => '/login';
  String pathGetInfo()=>'/getInfo';

  // 可选：通用请求方法
  // Future<Response> get(String path) => DioClient().get(path);
}
