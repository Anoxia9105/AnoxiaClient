import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 图形验证码数据
///
/// 保存验证码的唯一标识符和 Base64 编码的图片数据。
class SimpleCaptchaData {
  const SimpleCaptchaData({required this.uuid, required this.imgBase64});

  /// 验证码唯一标识
  final String uuid;

  /// Base64 编码的验证码图片
  final String imgBase64;
}

/// 忘记密码页图形验证码
///
/// 固定高度与输入框保持一致，鼠标悬浮时显示刷新遮罩，点击触发 [onTap] 刷新验证码。
class ForgotPasswordCaptchaImage extends StatefulWidget {
  const ForgotPasswordCaptchaImage({
    super.key,
    required this.captcha,
    required this.onTap,
    this.width = 120,
    this.height = 44,
  });

  /// 验证码数据，为空时显示加载占位
  final SimpleCaptchaData? captcha;

  /// 点击验证码刷新回调
  final VoidCallback onTap;

  /// 验证码容器宽度
  final double width;

  /// 验证码容器高度，与输入框高度保持一致
  final double height;

  @override
  State<ForgotPasswordCaptchaImage> createState() =>
      _ForgotPasswordCaptchaImageState();
}

class _ForgotPasswordCaptchaImageState extends State<ForgotPasswordCaptchaImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final captcha = widget.captcha;
    if (captcha == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  base64Decode(captcha.imgBase64),
                  fit: BoxFit.cover,
                ),
                if (_isHovering)
                  Container(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh01,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
