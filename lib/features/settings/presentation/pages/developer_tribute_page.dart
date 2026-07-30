import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 开发者致敬页面
///
/// 通过连续点击版本号触发的彩蛋页面，展示开发者致敬信息，
/// 带有动态渐变背景和闪烁粒子动画效果。

/// 开发者致敬页面组件
///
/// 全屏彩蛋页面，通过动画散发渐变背景和浮动粒子效果，
/// 展示对开发者的感谢和致敬。
class DeveloperTributePage extends StatefulWidget {
  const DeveloperTributePage({super.key});

  @override
  State<DeveloperTributePage> createState() => _DeveloperTributePageState();
}

/// 致敬页面状态
///
/// 管理渐变背景动画和粒子效果动画的控制器。
class _DeveloperTributePageState extends State<DeveloperTributePage>
    with SingleTickerProviderStateMixin {
  /// 动画控制器
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value * math.pi * 2;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(math.sin(t) * 0.35, -1),
                      end: Alignment(-math.sin(t) * 0.35, 1),
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.22),
                        colorScheme.surface,
                        colorScheme.tertiary.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SparklePainter(
                    progress: _controller.value,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final dy = math.sin(_controller.value * math.pi * 2) * 8;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      size: 54,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'settings_easter_title'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Center(
                      child: Text(
                        'settings_easter_body'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              height: 1.75,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'settings_easter_signature'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 闪烁粒子画笔
///
/// 在画布上绘制多个浮动闪烁的粒子点，用于致敬页面的装饰效果。
class _SparklePainter extends CustomPainter {
  /// 动画进度（0.0 - 1.0）
  final double progress;

  /// 粒子颜色
  final Color color;

  const _SparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final points = List.generate(18, (index) {
      final seed = index * 37.0;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final baseY = (math.cos(seed * 1.7) * 0.5 + 0.5) * size.height;
      final y = (baseY + progress * size.height * 0.22) % size.height;
      final radius = 2.5 + (index % 4) * 1.2;
      final alpha =
          0.12 + (math.sin(progress * math.pi * 2 + index) + 1) * 0.08;
      return (Offset(x, y), radius, alpha);
    });

    for (final point in points) {
      paint.color = color.withValues(alpha: point.$3);
      canvas.drawCircle(point.$1, point.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
