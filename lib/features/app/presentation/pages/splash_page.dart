import 'dart:math' as math;
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/app_initializer.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // 核心视觉控制器（Logo / 文本入场，执行一次）
  late AnimationController _controller;
  // 粒子持续动画控制器（无限循环，避免定住）
  late AnimationController _particleController;

  late Animation<double> _textDelayOpacity;

  bool _isExiting = false;

  // 轻量粒子列表
  final List<_Particle> _particles = List.generate(24, (i) => _Particle());

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 粒子独立的无限循环控制器（确保动画结束后粒子依旧在飘动）
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 底部品牌/加载文本优雅淡入
    _textDelayOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  /// 目标路由就绪后触发跳转。
  /// 启动页自身不再做“假预览+手动滑出”的动画——
  /// 真正的推离/滑入效果交给 router.dart 里的 CustomTransitionPage 联动完成，
  /// 这样只有一份真实页面在跑动画，不会出现“预览切真实页面”的闪跳。
  void _scheduleExit(String targetLocation) {
    if (_isExiting) return;
    _isExiting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 保证 Logo 入场动画播放完整，体验更连贯，避免动画播到一半就跳走
      if (!_controller.isCompleted) {
        await _controller.forward();
      }
      if (!mounted) return;
      context.go(targetLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final initStatus = ref.watch(appInitializerProvider);
    final authStatus = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final targetLocation = initStatus.hasValue
        ? authStatus.maybeWhen(
            data: (user) => user == null ? '/login' : '/',
            error: (_, _) => '/login',
            orElse: () => null,
          )
        : null;
    if (targetLocation != null) {
      _scheduleExit(targetLocation);
    }

    return _buildSplashOverlay(theme, primaryColor);
  }

  Widget _buildSplashOverlay(ThemeData theme, Color primaryColor) {
    return AppScaffold(
      hideAppBarLogo: true,
      body: Stack(
        children: [
          // 氛围底层：使用 _particleController 驱动，无限循环持续飘动
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                for (var p in _particles) {
                  p.update();
                }
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    color: primaryColor,
                  ),
                );
              },
            ),
          ),

          // 核心视觉层（Logo 及文本动画）
          Positioned.fill(
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 40),

                      // 图标主体
                      SizedBox(
                        width: 152,
                        height: 152,
                        child: Assets.images.appIconPng.image(fit: BoxFit.cover),
                      ),

                      // 优雅的底座
                      Opacity(
                        opacity: _textDelayOpacity.value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ANOXIA IM',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6.0,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Secure · High Performance · Cross-Platform',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  letterSpacing: 1.0,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: 64,
                                child: LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  color: primaryColor.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double baseOpacity;
  late double angle;

  _Particle() {
    _reset(isInitial: true);
  }

  void _reset({bool isInitial = false}) {
    final random = math.Random();
    x = random.nextDouble();
    // 初始离散在全屏，后续生成的粒子则严格从底部往上走
    y = isInitial ? random.nextDouble() : 1.1;
    size = random.nextDouble() * 3.0 + 1.2;
    speed = random.nextDouble() * 0.05 + 0.02;
    baseOpacity = random.nextDouble() * 0.28 + 0.12;
    angle = random.nextDouble() * math.pi * 2;
  }

  // 每帧固定步长更新，不依赖全局 progress
  void update() {
    y -= speed * 0.016;
    x += math.sin(angle + y * 4) * 0.0012;
    if (y < -0.1 || x < -0.1 || x > 1.1) {
      _reset();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (var p in particles) {
      final position = Offset(p.x * size.width, p.y * size.height);
      double edgeAlpha = 1.0;
      if (p.y < 0.2) edgeAlpha = p.y / 0.2;

      paint.color = color.withValues(alpha: p.baseOpacity * edgeAlpha);
      canvas.drawCircle(position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}