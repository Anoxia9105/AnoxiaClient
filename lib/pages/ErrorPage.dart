import 'package:flutter/material.dart';
import 'package:notepadclient/pages/AppScaffold.dart';

import '../common/utils/DeviceUtil.dart';
import '../common/widgets/desktop/DesktopAppBar.dart';
import '../framework/theme/AppColors.dart';

class ErrorPage extends StatelessWidget {
  final String? message;

  const ErrorPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64),
            Text(message ?? "发生未知错误"), // 💡 显示错误信息
            // ... 重试按钮 ...
          ],
        ),
      ),
    );
  }
}
