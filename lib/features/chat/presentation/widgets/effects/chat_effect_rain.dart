import 'dart:math' as math;

import 'package:anoxia/domain/models/chat_effect_rule.dart';
import 'package:flutter/material.dart';

/// 仅绘制下落粒子，不展示卡片、弹窗或文字，不重建下面的消息列表。
class ChatEffectRain extends StatefulWidget {
  const ChatEffectRain({
    super.key,
    required this.rule,
    required this.onCompleted,
    required this.particleCount,
  });

  final ChatEffectRule rule;
  final VoidCallback onCompleted;
  final int particleCount;

  @override
  State<ChatEffectRain> createState() => _ChatEffectRainState();
}

class _ChatEffectRainState extends State<ChatEffectRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final _RainPainter _painter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rule.duration,
    );
    _painter = _RainPainter(_controller, widget.rule, widget.particleCount);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: ClipRect(
        child: RepaintBoundary(
          child: CustomPaint(painter: _painter, size: Size.infinite),
        ),
      ),
    ),
  );
}

class _RainParticle {
  _RainParticle(math.Random random, int spriteCount)
    : x = random.nextDouble(),
      delay = random.nextDouble() * .22,
      drift = random.nextDouble() * 100 - 50,
      rotation = random.nextDouble() * 1.4 - .7,
      scale = .7 + random.nextDouble() * .5,
      sprite = random.nextInt(spriteCount);

  final double x, delay, drift, rotation, scale;
  final int sprite;
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.animation, ChatEffectRule rule, int count)
    : super(repaint: animation) {
    // 每种 emoji 只排版一次，随机轨迹也只在动画开始时生成。
    for (final emoji in rule.emojis) {
      _sprites.add(
        TextPainter(
          text: TextSpan(
            text: emoji,
            style: const TextStyle(
              fontSize: 32,
              fontFamilyFallback: [
                'Apple Color Emoji',
                'Segoe UI Emoji',
                'Noto Color Emoji',
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }
    final random = math.Random();
    _particles = List.generate(
      count,
      (_) => _RainParticle(random, _sprites.length),
    );
  }

  final Animation<double> animation;
  final _sprites = <TextPainter>[];
  late final List<_RainParticle> _particles;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final opacity = ((1 - progress) / .12).clamp(0.0, .9);
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    for (final particle in _particles) {
      final t = (progress - particle.delay) / (1 - particle.delay);
      if (t < 0 || t > 1) continue;
      final sprite = _sprites[particle.sprite];
      final x = particle.x * math.max(0, size.width - 40) + particle.drift * t;
      final y = -60 + (size.height + 120) * t;
      canvas.save();
      canvas.translate(x + 16, y + 16);
      canvas.rotate(particle.rotation * t);
      canvas.scale(particle.scale);
      sprite.paint(canvas, Offset(-sprite.width / 2, -sprite.height / 2));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => oldDelegate != this;

  void dispose() {
    for (final sprite in _sprites) {
      sprite.dispose();
    }
  }
}
