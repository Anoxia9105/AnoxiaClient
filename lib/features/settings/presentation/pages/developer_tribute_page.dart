import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

/// 开发者致敬 / 彩蛋页面
///
/// 通过连续点击版本号触发。目标是“真诚而克制”——不煽情、不浮夸，
/// 用具体的细节与稳定的视觉，让用户感受到“有人在认真做这件事”。
class DeveloperTributePage extends StatefulWidget {
  const DeveloperTributePage({super.key});

  @override
  State<DeveloperTributePage> createState() => _DeveloperTributePageState();
}

class _DeveloperTributePageState extends State<DeveloperTributePage>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _heartController;
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _heartController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: '${'settings_easter_title'.tr()}\n\n${'settings_easter_body'.tr()}\n\n— ${'settings_easter_signature'.tr()}',
          title: 'Anoxia',
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 渐变背景
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, _) {
                final t = _bgController.value * math.pi * 2;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(math.sin(t) * 0.45, -1),
                      end: Alignment(-math.sin(t) * 0.45, 1),
                      colors: isDark
                          ? [
                              scheme.primary.withValues(alpha: 0.18),
                              const Color(0xFF0F1220),
                              scheme.tertiary.withValues(alpha: 0.14),
                            ]
                          : [
                              scheme.primary.withValues(alpha: 0.16),
                              scheme.surface,
                              scheme.tertiary.withValues(alpha: 0.12),
                            ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 模糊光斑
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, _) {
                final p = _bgController.value;
                return CustomPaint(
                  painter: _GlowPainter(progress: p, isDark: isDark, primary: scheme.primary, tertiary: scheme.tertiary),
                );
              },
            ),
          ),
          // 粒子
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, _) => CustomPaint(
                painter: _SparklePainter(progress: _bgController.value, color: scheme.primary),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 14, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text('EASTER EGG · 07 TAPS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  sliver: SliverList.list(
                    children: [
                      // 心跳图标
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic)),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _heartController,
                              builder: (_, child) {
                                final scale = 1 + _heartController.value * 0.07;
                                final dy = math.sin(_bgController.value * math.pi * 2) * 6;
                                return Transform.translate(
                                  offset: Offset(0, dy),
                                  child: Transform.scale(scale: scale, child: child),
                                );
                              },
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
                                  boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
                                ),
                                alignment: Alignment.center,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 42, color: scheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _enterController, curve: const Interval(0.15, 0.85, curve: Curves.easeOut)),
                        child: Column(
                          children: [
                            Text(
                              'settings_easter_title'.tr(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.2, color: scheme.onSurface),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                              child: Text('你连续点击了 7 次才来到这里 · 谢谢你的好奇心', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // 主信件卡片
                      _EntranceCard(
                        delay: 120,
                        controller: _enterController,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: isDark ? 0.72 : 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06), blurRadius: 24, offset: const Offset(0, 12))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 3, height: 18, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(999))),
                                  const SizedBox(width: 10),
                                  Text('一封小小的信', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  const Spacer(),
                                  HugeIcon(icon: HugeIcons.strokeRoundedMail01, size: 18, color: scheme.onSurfaceVariant),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'settings_easter_body'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.85, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('那些没有说出口的细节', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                                    const SizedBox(height: 8),
                                    const _Bullet(text: '凌晨两点还在对齐一条消息的 seq 与时间戳，只为不丢一条“在吗”。'),
                                    const _Bullet(text: '把“发送失败”改成能看懂的原因，而不是冷冰冰的 code。'),
                                    const _Bullet(text: '在弱网、息屏、来回切换时，依然把未读数算对。'),
                                    const _Bullet(text: '为每一个头像、气泡、动效，调过十几遍圆角与阴影。'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Anoxia 还不完美，也永远不会“做完”。但每一次修复、每一次为 0.1 秒的跟手度较真，都是想让你在重要的对话里，更安心一点。\n\n如果你愿意，留下一句反馈，或把 Anoxia 推荐给在乎的人——那就是对这份坚持最好的回应。',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.75, color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('settings_easter_signature'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    Text('Anoxia · 2024 — 至今', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 三个价值观
                      _EntranceCard(
                        delay: 220,
                        controller: _enterController,
                        child: const Row(
                          children: [
                            Expanded(child: _ValueCard(icon: HugeIcons.strokeRoundedShield01, title: '稳定', desc: '消息不丢\n未读算对')),
                            SizedBox(width: 10),
                            Expanded(child: _ValueCard(icon: HugeIcons.strokeRoundedHeartCheck, title: '真诚', desc: '说人话\n不打扰')),
                            SizedBox(width: 10),
                            Expanded(child: _ValueCard(icon: HugeIcons.strokeRoundedSparkles, title: '陪伴', desc: '轻一点\n久一点')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 语录
                      _EntranceCard(
                        delay: 320,
                        controller: _enterController,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: isDark ? 0.22 : 0.42),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedQuoteDown, size: 20, color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '“把重要的事，说清楚；把普通的日子，过轻盈。”',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.6, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // 操作
                      _EntranceCard(
                        delay: 420,
                        controller: _enterController,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _share,
                                icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18),
                                label: Text('分享这份心意'.tr()),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 18),
                                label: const Text('收下了'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text('彩蛋会在下次点击版本号时再次出现', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntranceCard extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final int delay;
  const _EntranceCard({required this.child, required this.controller, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final intervalStart = (delay / 700).clamp(0.0, 0.9);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = CurvedAnimation(parent: controller, curve: Interval(intervalStart, 1, curve: Curves.easeOutCubic)).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6, color: scheme.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String desc;
  const _ValueCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: HugeIcon(icon: icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.4, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color primary;
  final Color tertiary;
  const _GlowPainter({required this.progress, required this.isDark, required this.primary, required this.tertiary});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(size.width * (0.22 + math.sin(progress * math.pi * 2) * 0.08), size.height * 0.18);
    final p2 = Offset(size.width * (0.78 + math.cos(progress * math.pi * 2 * 0.9) * 0.06), size.height * 0.72);
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    paint.color = primary.withValues(alpha: isDark ? 0.10 : 0.09);
    canvas.drawCircle(p1, size.width * 0.28, paint);
    paint.color = tertiary.withValues(alpha: isDark ? 0.09 : 0.07);
    canvas.drawCircle(p2, size.width * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.progress != progress;
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _SparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final points = List.generate(20, (index) {
      final seed = index * 41.0;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final baseY = (math.cos(seed * 1.6) * 0.5 + 0.5) * size.height;
      final y = (baseY + progress * size.height * 0.18) % size.height;
      final radius = 1.8 + (index % 4) * 1.1;
      final alpha = 0.08 + (math.sin(progress * math.pi * 2 + index) + 1) * 0.07;
      return (Offset(x, y), radius, alpha);
    });
    for (final point in points) {
      paint.color = color.withValues(alpha: point.$3);
      canvas.drawCircle(point.$1, point.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
