import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 错误页面
///
/// 用于展示应用运行时发生的错误，支持自定义错误消息。
/// 当错误消息为 null 时，显示默认的未知错误提示。
class ErrorPage extends StatelessWidget {
  /// 自定义错误消息
  ///
  /// 若为 null，则显示默认的未知错误文案
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
            Text(message ?? 'error_unknown'.tr()),
          ],
        ),
      ),
    );
  }
}
