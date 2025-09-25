
abstract class ApiBase {


  //匿名接口
  String pathCaptchaImage() => '/captchaImage';
  String pathLogin() => '/login';
  String pathLogout()=>'/logout';

  //登录用户接口
  String pathGetInfo()=>'/getInfo';
  //刷新token
  String pathRefreshToken()=>'/refresh';

  String pathSocket(String token) => '/chat?token=$token';

  //聊天室接口
  String pathRoomList()=>'/chat/getRoomList';
// 可选：通用请求方法
  // Future<Response> get(String path) => DioClient().get(path);
}
