import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:flutter/material.dart';

/// 启动页/闪屏页
///
/// 应用启动时展示的页面，包含 Logo 动画和加载指示器
/// 使用多段式动画：Logo 缩放和淡入，营造高级感
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  /// 动画总控制器
  late AnimationController _controller;

  /// Logo 缩放动画（0.3→1.0
  late Animation<double> _logoScale;

  /// Logo 透明度动画（0→1，前 60% 时间完成
  late Animation<double> _logoOpacity;

  /// 加载指示器透明度动画（0→1，后 50% 时间完成
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // 总时长 2 秒
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo 缩放，用弹性曲线更有生命力
    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Logo 淡入，先出现
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    // 加载圈后出现，形成层次感
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
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
    return AppScaffold(
      hideAppBarLogo: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Assets.images.appIconPng.image(fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: const CircularProgressIndicator(strokeWidth: 3),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
