import 'package:flutter/material.dart';

import '../framework/theme/AppColors.dart';

class ErrorPage extends StatelessWidget {
  final String? message;

  const ErrorPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              Text(message ?? "发生未知错误"), // 💡 显示错误信息
              // ... 重试按钮 ...
            ],
          ),
        ),
      ),
    );
  }
}
