import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepadclient/core/constants/StorageKeys.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/domain/captcha.dart';
import 'package:notepadclient/core/network/TokenManager.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/features/contact/service/IContactService.dart';
import 'package:notepadclient/features/layout/controller/layout_controller.dart.dart';

import '../../../core/di/injector.dart';
import '../../../shared/widgets/FocusOverlayManager.dart';
import '../../chat/service/IChatService.dart';
import '../../contact/controller/ContactController.dart';
import '../service/IAuthService.dart';

/// 用户认证控制器
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:42
class AuthController extends ChangeNotifier {
  ///依赖注入服务实例
  final IAuthService _authService = getIt<IAuthService>();
  final IChatService _chatService = getIt<IChatService>();
  final IContactService _contactService = getIt<IContactService>();
  ///注入控制器
  final LayoutController _layoutController = getIt<LayoutController>();
  final ChatController _chatController = getIt<ChatController>();
  final ContactController _contactController = getIt<ContactController>();

  AuthController() {
    _initAutoLogin();
  }

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _onLogin = false;

  bool get onLogin => _onLogin;

  set onLogin(bool value) {
    _onLogin = value;
    notifyListeners();
  }

  bool _autoLogin = false;

  bool get autoLogin => _autoLogin;

  set autoLogin(bool value) {
    _autoLogin = value;
    notifyListeners();
  }

  bool _obscure = true;

  bool get obscure => _obscure;

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  Uint8List? bytes;
  Captcha? captcha;
  SysUser? userInfo;

  /// 自动登录
  Future<void> _initAutoLogin() async {
    try {
      autoLogin = true;
      await _loginInit(await _authService.login(autoLogin: true));
    } catch (e, t) {
      _handleError("自动登录失败", e, t);
      logout();
      autoLogin = false;
    }
  }

  /// 加载验证码
  Future<void> loadCaptcha() async {
    try {
      captcha = await _authService.getCaptchaImage();
      if (captcha?.code == 200 && captcha?.img != null) {
        bytes = base64Decode(captcha!.img!);
      }
      notifyListeners();
    } catch (e, t) {
      _handleError("加载验证码失败", e, t);
    }
  }

  /// 用户登录
  Future<void> login(BuildContext context) async {
    onLogin = true;
    FocusOverlayManager.show(
      context,
      const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("登录中，请稍候..."),
          ],
        ),
      ),
    );

    try {
      await _loginInit(
        await _authService.login(
          loginData: {
            "username": nameController.text.trim(),
            "password": passwordController.text.trim(),
            "code": captchaController.text.trim(),
            "uuid": captcha?.uuid ?? '',
          },
        ),
      );
    } catch (e, t) {
      _handleError("登录失败", e, t);
    } finally {
      FocusOverlayManager.hide();
      onLogin = false;
    }
  }

  /// 登录成功初始化
  Future<void> _loginInit(SysUser? user) async {
    if (user != null && user.code == HttpStatus.ok) {
      var userId = user.data?.userId;

      //保存用户信息
      userInfo = user;

      //初始化聊天室
      _chatController.roomSummaryList = await _chatService.getChatList(userId);
      //初始化联系人
      _contactController.contactList =await _contactService.getContactList(userId);
      //初始化联系人申请
      _contactController.contactRequestList = await _contactService.getContactRequestList(userId);


      _layoutController.login = true;
      return;
    }
    _resetCaptcha();
    autoLogin = false;
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      await _authService.logout();
      // 通过 TokenManager 写入（含过期）
      await TokenManager.instance.clearToken();
      await SPUtil.instance.remove(StorageKeys.sysUser);

      _layoutController.login = false;
      userInfo = null;
      nameController.clear();
      passwordController.clear();
      captchaController.clear();

      _resetCaptcha();
      notifyListeners();
    } catch (e, t) {
      _handleError("登出失败", e, t);
    }
  }

  /// 刷新验证码并清空输入
  void _resetCaptcha() {
    captchaController.clear();
    loadCaptcha();
  }

  /// 错误处理
  void _handleError(String msg, Object e, StackTrace t) {
    debugPrint("$msg: $e\n$t");
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    captchaController.dispose();
    super.dispose();
  }
}
