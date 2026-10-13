import 'dart:math' as math;
import 'dart:typed_data';

import 'package:anoxia/domain/models/chat_effect_rule.dart';
import 'package:flutter/material.dart';

import 'chat_effect_sprite_atlas.dart';

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
  _RainPainter? _painter;
  double? _pixelRatio;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rule.duration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ratio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    if (_pixelRatio == ratio) return;
    _pixelRatio = ratio;
    _painter?.dispose();
    _painter = _RainPainter(
      _controller,
      widget.rule,
      widget.particleCount,
      ratio,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _painter?.dispose();
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
  _RainPainter(
    this.animation,
    ChatEffectRule rule,
    int count,
    double pixelRatio,
  ) : _atlas = ChatEffectSpriteAtlas(rule.emojis, pixelRatio),
      _transforms = Float32List(count * 4),
      _rects = Float32List(count * 4),
      _colors = Int32List(count),
      super(repaint: animation) {
    final random = math.Random();
    _particles = List.generate(
      count,
      (_) => _RainParticle(random, rule.emojis.length),
    );
    for (var i = 0; i < count; i++) {
      final cell = _atlas.cells[_particles[i].sprite];
      final offset = i * 4;
      _rects[offset] = cell.left;
      _rects[offset + 1] = cell.top;
      _rects[offset + 2] = cell.right;
      _rects[offset + 3] = cell.bottom;
    }
  }

  final Animation<double> animation;
  final ChatEffectSpriteAtlas _atlas;
  final Float32List _transforms, _rects;
  final Int32List _colors;
  final _paint = Paint()..filterQuality = FilterQuality.low;
  late final List<_RainParticle> _particles;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final opacity = ((1 - progress) / .12).clamp(0.0, .9);
    final color = ((opacity * 255).round() << 24) | 0x00ffffff;
    final anchor = _atlas.cellPixels / 2;
    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final offset = i * 4;
      _colors[i] = color;
      final t = (progress - particle.delay) / (1 - particle.delay);
      if (t < 0 || t > 1) {
        _transforms[offset] = 0;
        _transforms[offset + 1] = 0;
        continue;
      }
      final x = particle.x * math.max(0, size.width - 40) + particle.drift * t;
      final y = -60 + (size.height + 120) * t;
      final scale = particle.scale / _atlas.pixelRatio;
      final angle = particle.rotation * t;
      final scos = math.cos(angle) * scale;
      final ssin = math.sin(angle) * scale;
      _transforms[offset] = scos;
      _transforms[offset + 1] = ssin;
      _transforms[offset + 2] = x + 16 - anchor * scos + anchor * ssin;
      _transforms[offset + 3] = y + 16 - anchor * ssin - anchor * scos;
    }
    // 每帧一次纹理批量绘制，透明度逐粒子调制，避免全屏 saveLayer。
    canvas.drawRawAtlas(
      _atlas.image,
      _transforms,
      _rects,
      _colors,
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => oldDelegate != this;

  void dispose() => _atlas.dispose();
}
