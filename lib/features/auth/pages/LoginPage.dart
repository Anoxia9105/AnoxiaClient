import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/features/layout/widgets/LayoutHeader.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injector.dart';

AuthController authController = getIt<AuthController>();

/// 登录页面（带验证码）
///
/// 作者: anoxia
/// 版本: 1.1.0
/// 创建时间: 2025-09-16
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    authController.loadCaptcha();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.grey.shade800;
    double width = DeviceUtil.isDesktop ? 150.w : 300.w;
    return Consumer<AuthController>(
      builder: (BuildContext context, AuthController auth, Widget? child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, // 或者 Alignment.topLeft
              end: Alignment.bottomCenter, // 或者 Alignment.bottomRight
              colors: [
                Color(0xFFDEE4EA), // 浅蓝灰
                Color(0xFFC3CBD6), // 深一点的蓝灰
                Color(0xFFE6E6E9), // 灰色
                Color(0xFFEDEDED), // 银白
                Color(0xFFD0CCDF), // 浅紫灰
              ],
            ),
          ),
          child: Scaffold(
            appBar: LayoutHeader().getAppbar(color: Colors.black),
            body: Center(
              child: SizedBox(
                width: width,
                child: Form(
                  key: auth.formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Application.getAppLogo(width: 30, height: 30),
                          SizedBox(width: 5.w),
                          Text(
                            "login_page_title".tr(),
                            style: TextStyle(fontSize: 20, color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),

                      TextFormField(
                        style: TextStyle(color: textColor),
                        controller: auth.emailController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: textColor),
                          hintText: 'login_page_name'.tr(),
                          iconColor: textColor,
                          errorStyle: TextStyle(color: Colors.red),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          fillColor: Colors.transparent,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: textColor,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "请输入用户名";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),

                      TextFormField(
                        style: TextStyle(color: textColor, letterSpacing: -1),
                        controller: auth.passwordController,
                        keyboardType: TextInputType.number,
                        // obscuringCharacter: '●',
                        obscureText: auth.obscure,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: textColor),
                          hintText: 'login_page_password'.tr(),
                          errorStyle: TextStyle(color: Colors.red),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          iconColor: textColor,
                          fillColor: Colors.transparent,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: textColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          // focusedBorder: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(8.r),
                          //   borderSide: const BorderSide(color: Colors.blue),
                          // ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              color: textColor,
                              auth.obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              auth.setObscure();
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              style: TextStyle(color: textColor),
                              controller: auth.captchaController,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                errorStyle: TextStyle(color: Colors.red),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                hintStyle: TextStyle(color: textColor),
                                hintText: 'login_page_captcha'.tr(),
                                iconColor: textColor,
                                fillColor: Colors.transparent,
                                prefixIcon: Icon(
                                  Icons.code_rounded,
                                  color: textColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                // focusedBorder: OutlineInputBorder(
                                //   borderRadius: BorderRadius.circular(8.r),
                                //   borderSide: const BorderSide(color: Colors.blue),
                                // ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          if (auth.bytes == null)
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  color: textColor,
                                ),
                              ),
                            )
                          else
                            MouseRegion(
                              cursor: SystemMouseCursors.click, // 小手光标
                              child: GestureDetector(
                                onTap: () {
                                  auth.loadCaptcha();
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    8.r,
                                  ), // 圆角半径
                                  child: Image.memory(
                                    auth.bytes!,
                                    width: 100,
                                    height: 40,
                                    fit: BoxFit.fill,
                                    gaplessPlayback: true, // 防止刷新时闪烁
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "login_page_forget".tr(),
                            style: TextStyle(color: Colors.blue),
                          ),
                          Text(
                            "login_page_register".tr(),
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: width,
                        child: FilledButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              EdgeInsets.all(15),
                            ),
                          ),
                          onPressed: () {
                            if (auth.formKey.currentState!.validate()) {
                              auth.login(context);
                            }
                          },
                          child: Text(
                            "login_page_login".tr(),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
