import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 音频通话背景组件
///
/// 显示渐变背景 + 装饰光球 + 通话图标 + 房间名称
class AudioCallBackground extends StatelessWidget {
  const AudioCallBackground({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202638), Color(0xFF11141D), Color(0xFF080A0F)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: GlowOrb(size: 260, color: Color(0x334F7DFF)),
          ),
          const Positioned(
            bottom: 100,
            left: -90,
            child: GlowOrb(size: 240, color: Color(0x2256E39F)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 116),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCall02,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'call_voice_call_in_progress'.tr(),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
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