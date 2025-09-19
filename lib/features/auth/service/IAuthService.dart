import 'package:notepadclient/core/domain/captcha.dart';

abstract class IAuthService{
  Future<Captcha> getCaptchaImage();
}