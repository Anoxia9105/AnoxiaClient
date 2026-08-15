import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 音频通话背景组件
///
/// 显示渐变背景 + 装饰光球 + 通话图标 + 房间名称。
/// 背景跟随应用主题（scaffoldGradient），图标/文字颜色取自 colorScheme，
/// 尺寸按屏幕宽度缩放，避免小屏上图标过大。
class AudioCallBackground extends StatelessWidget {
  const AudioCallBackground({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final scale = (MediaQuery.sizeOf(context).width / 375).clamp(0.85, 1.1);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: GlowOrb(
              size: 260 * scale,
              color: cs.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -90,
            child: GlowOrb(
              size: 240 * scale,
              color: cs.tertiary.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 116),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88 * scale,
                    height: 88 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: 0.1),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCall02,
                      color: cs.primary,
                      size: 36 * scale,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'call_voice_call_in_progress'.tr(),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 装饰光球组件
class GlowOrb extends StatelessWidget {
  const GlowOrb({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 25)],
      ),
    );
  }
}
