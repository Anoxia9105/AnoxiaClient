import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/network/DioClient.dart';
import 'package:notepadclient/core/utils/StringUtil.dart';
import 'package:notepadclient/features/auth/service/IAuthService.dart';

import '../../../../core/constants/StorageKeys.dart';
import '../../../../core/di/injector.dart';

class AuthServiceImpl extends ApiBase implements IAuthService {

  FlutterSecureStorage flutterSecureStorage = getIt<FlutterSecureStorage>();

  final DioClient client=DioClient();

  @override
  Future<Captcha> getCaptchaImage() async {
    final response = await client.get(pathCaptchaImage(), auth: false);
    return Captcha.fromJson(response.data);
  }

  @override
  Future<SysUser?> loginByToken(Map<String,String> loginData) async {
    final response = await client.post(pathLogin(),data: loginData, auth: false);
    print(response);
    String token=response.data["token"] ?? '';
    if(StringUtil.isNotEmpty(token)){
      flutterSecureStorage.write(key: StorageKeys.accessToken, value: token);
      final userInfo=await client.get(pathGetInfo());
      SysUser user= SysUser.fromJson(userInfo);
      return user;
    }
    return null;
  }
}