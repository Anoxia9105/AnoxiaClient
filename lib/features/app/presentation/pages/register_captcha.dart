import 'dart:convert';

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 注册页验证码图片
class RegisterCaptchaImage extends ConsumerStatefulWidget {
  const RegisterCaptchaImage({
    super.key,
    required this.width,
    required this.onTap,
  });

  final double width;
  final VoidCallback onTap;

  @override
  ConsumerState<RegisterCaptchaImage> createState() =>
      _RegisterCaptchaImageState();
}

class _RegisterCaptchaImageState extends ConsumerState<RegisterCaptchaImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ref
        .watch(getCaptchaProvider)
        .when(
          data: (captcha) => MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: Material(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              clipBehavior: Clip.antiAlias,
              color: scheme.surfaceContainerHigh,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(RadiusToken.lg),
                child: SizedBox(
                  width: widget.width,
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        base64Decode(captcha.imgBase64),
                        fit: BoxFit.cover,
                      ),
                      if (_isHovering)
                        Container(
                          color: scheme.primary.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedRefresh01,
                            color: scheme.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          loading: () => SizedBox(
            width: widget.width,
            height: 44,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(RadiusToken.lg),
              ),
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => SizedBox(
            width: widget.width,
            height: 44,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(RadiusToken.lg),
              ),
              child: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh01,
                  color: scheme.onErrorContainer,
                ),
                onPressed: widget.onTap,
              ),
            ),
          ),
        );
  }
}
