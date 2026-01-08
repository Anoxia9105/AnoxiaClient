import 'package:flutter/material.dart';

import '../framework/theme/AppColors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    //获取主题渐变色
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(child: CircularProgressIndicator()),
      ), // 或者是你的 Logo 启动页
    );
  }
}
