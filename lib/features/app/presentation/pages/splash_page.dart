import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _indicatorOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Logo 缩放，弹性落下
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Logo 淡入
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45),
      ),
    );

    // 光晕淡入
    _glowOpacity = Tween<double>(begin: 0, end: 0.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7),
      ),
    );

    // 扩散圆环：从1.0放大到1.6并淡出
    _ringScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    // 底部指示器
    _indicatorOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return AppScaffold(
      hideAppBarLogo: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 扩散光圈
                      Opacity(
                        opacity: (1 -
                                ((_ringScale.value - 1.0) / 0.6).clamp(
                                  0.0,
                                  1.0,
                                )) *
                            _glowOpacity.value *
                            2,
                        child: Transform.scale(
                          scale: _ringScale.value,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 背景光晕
                      Opacity(
                        opacity: _glowOpacity.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primaryColor.withValues(alpha: 0.4),
                                primaryColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Logo 本体
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Assets.images.appIconPng
                                  .image(fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 56),

            // 底部加载指示器
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Opacity(
                  opacity: _indicatorOpacity.value,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}