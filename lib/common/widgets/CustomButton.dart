import 'package:flutter/material.dart';

/// 自定义按钮组件
///
/// 提供统一的按钮样式，支持加载状态展示。
class CustomButton extends StatelessWidget {
  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否显示加载状态
  final bool loading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
