import 'dart:convert';

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class CaptchaImage extends ConsumerStatefulWidget {
  const CaptchaImage({super.key});

  @override
  ConsumerState<CaptchaImage> createState() => _CaptchaImageState();
}

class _CaptchaImageState extends ConsumerState<CaptchaImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ref
        .watch(getCaptchaProvider)
        .when(
          data: (captcha) {
            return Tooltip(
              message: 'login_page_captcha'.tr(),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click,
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  color: colorScheme.surfaceContainerHigh,
                  child: InkWell(
                    onTap: () => ref.invalidate(getCaptchaProvider),
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 120,
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
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
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
              ),
            );
          },
          loading: () => Container(
            width: 120,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, st) => Container(
            width: 120,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh01,
                color: colorScheme.onErrorContainer,
              ),
              onPressed: () => ref.invalidate(getCaptchaProvider),
            ),
          ),
        );
  }
}
