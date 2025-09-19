import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/network/DioClient.dart';
import 'package:notepadclient/features/auth/service/IAuthService.dart';

class AuthServiceImpl extends ApiBase implements IAuthService {
  @override
  Future<Captcha> getCaptchaImage() async {
    final response = await DioClient().get(pathCaptchaImage(), auth: false);
    return Captcha.fromJson(response.data);
  }
}