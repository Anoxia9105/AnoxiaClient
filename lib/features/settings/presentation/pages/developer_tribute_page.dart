import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 藏在版本号后的短信。页面主题只用于阅读预览，不修改应用外观设置。
class DeveloperTributePage extends StatefulWidget {
  const DeveloperTributePage({super.key});

  @override
  State<DeveloperTributePage> createState() => _DeveloperTributePageState();
}

class _DeveloperTributePageState extends State<DeveloperTributePage> {
  final _scroll = ScrollController();
  final _acceptFocus = FocusNode();
  final _reopenFocus = FocusNode();
  Brightness? _brightness;
  bool _received = false;

  void _showReceived(bool value) {
    setState(() => _received = value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (value ? _reopenFocus : _acceptFocus).requestFocus();
    });
  }

  Future<void> _copyQuote() async {
    var message = 'settings_easter_copy_success'.tr();
    try {
      await Clipboard.setData(
        ClipboardData(text: 'settings_easter_quote'.tr()),
      );
    } catch (_) {
      message = 'settings_easter_copy_failure'.tr();
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _acceptFocus.dispose();
    _reopenFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final colors = _LetterColors(dark);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            final horizontal = compact
                ? SpacingToken.xl
                : SpacingToken.xxl + SpacingToken.lg;
            return SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontal,
                        vertical: SpacingToken.md,
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            key: const Key('easter-back'),
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.body,
                            ),
                            icon: const Icon(Icons.chevron_left, size: 18),
                            label: Text('common_back'.tr()),
                          ),
                          const SizedBox(width: SpacingToken.lg),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Anoxia.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w500,
                                            color: colors.ink,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: SpacingToken.xl),
                                IconButton.outlined(
                                  key: const Key('easter-theme'),
                                  tooltip:
                                      (dark
                                              ? 'settings_easter_theme_light'
                                              : 'settings_easter_theme_dark')
                                          .tr(),
                                  isSelected: dark,
                                  onPressed: () => setState(
                                    () => _brightness = dark
                                        ? Brightness.light
                                        : Brightness.dark,
                                  ),
                                  style: IconButton.styleFrom(
                                    foregroundColor: colors.body,
                                    backgroundColor: Colors.transparent,
                                    shape: const CircleBorder(),
                                    side: BorderSide(color: colors.line),
                                  ),
                                  icon: Icon(
                                    dark
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: compact ? SpacingToken.lg : SpacingToken.xxl,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingToken.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Container(
                        key: const Key('easter-letter'),
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          compact
                              ? SpacingToken.xl
                              : SpacingToken.xxl * 2 + SpacingToken.md,
                          compact
                              ? SpacingToken.xxl
                              : SpacingToken.xxl + SpacingToken.xl,
                          compact
                              ? SpacingToken.xl
                              : SpacingToken.xxl * 2 + SpacingToken.md,
                          compact
                              ? SpacingToken.xl
                              : SpacingToken.xxl + SpacingToken.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.paper,
                          border: Border.all(color: colors.line),
                          borderRadius: BorderRadius.circular(RadiusToken.sm),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? 0.1 : 0.035,
                              ),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: _received
                            ? _receipt(colors, compact)
                            : _letter(colors, compact),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingToken.xl,
                      SpacingToken.xl,
                      SpacingToken.xl,
                      SpacingToken.xxl,
                    ),
                    child: Text(
                      'settings_easter_footer'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.muted,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _letter(_LetterColors colors, bool compact) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: compact ? 13 : 14,
      height: 2.15,
      color: colors.body,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 80),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: SpacingToken.sm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 4),
                    ),
                  ),
                  const SizedBox(width: SpacingToken.md),
                  Expanded(
                    child: Text(
                      'settings_easter_eyebrow'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.8,
                        color: colors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -SpacingToken.md,
              right: 0,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -0.14,
                  child: CustomPaint(
                    size: Size(compact ? 56 : 78, compact ? 50 : 70),
                    painter: _EnvelopePainter(
                      colors.accent,
                      colors.paper,
                      colors.soft,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingToken.xxl),
        Semantics(
          header: true,
          child: Text(
            'settings_easter_title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: compact ? 28 : 36,
              height: 1.65,
              fontWeight: FontWeight.w500,
              color: colors.ink,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: SpacingToken.xl),
        Text('settings_easter_opening'.tr(), style: bodyStyle),
        const SizedBox(height: SpacingToken.lg),
        Text('settings_easter_reflection'.tr(), style: bodyStyle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingToken.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: compact ? SpacingToken.lg : SpacingToken.xl,
                child: Divider(
                  color: colors.accent.withValues(alpha: 0.5),
                  thickness: 1,
                ),
              ),
              const SizedBox(width: SpacingToken.lg),
              Expanded(
                child: Text(
                  'settings_easter_quote'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 18 : 21,
                    height: 1.75,
                    color: colors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text('settings_easter_closing'.tr(), style: bodyStyle),
        const SizedBox(height: SpacingToken.xl),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '— ${'settings_easter_signature'.tr()}',
            style: TextStyle(color: colors.body, fontSize: 12, height: 1.8),
          ),
        ),
        const SizedBox(height: SpacingToken.xxl),
        Divider(color: colors.line, height: 1),
        const SizedBox(height: SpacingToken.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(13) > 19;
            final copy = TextButton.icon(
              key: const Key('easter-copy'),
              onPressed: _copyQuote,
              style: TextButton.styleFrom(
                foregroundColor: colors.body,
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingToken.md,
                  horizontal: SpacingToken.xs,
                ),
              ),
              icon: const Icon(Icons.content_copy_outlined, size: 15),
              label: Text('settings_easter_copy'.tr()),
            );
            final accept = FilledButton(
              key: const Key('easter-accept'),
              focusNode: _acceptFocus,
              onPressed: () => _showReceived(true),
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: colors.button,
                foregroundColor: colors.buttonInk,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.xl,
                  vertical: SpacingToken.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.sm),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('settings_easter_accept'.tr())),
                  const SizedBox(width: SpacingToken.xl),
                  const Icon(Icons.arrow_forward, size: 17),
                ],
              ),
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  accept,
                  const SizedBox(height: SpacingToken.sm),
                  Align(child: copy),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: copy),
                const SizedBox(width: SpacingToken.lg),
                Flexible(child: accept),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _receipt(_LetterColors colors, bool compact) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: compact ? 500 : 580),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: colors.soft, shape: BoxShape.circle),
          child: Icon(Icons.favorite_border, color: colors.accent, size: 28),
        ),
        const SizedBox(height: SpacingToken.xxl),
        Semantics(
          header: true,
          child: Text(
            'settings_easter_received_title'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w500,
              height: 1.75,
              color: colors.ink,
            ),
          ),
        ),
        const SizedBox(height: SpacingToken.lg),
        Text(
          'settings_easter_received_body'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 2, color: colors.body),
        ),
        const SizedBox(height: SpacingToken.xxl),
        TextButton(
          key: const Key('easter-reopen'),
          focusNode: _reopenFocus,
          onPressed: () => _showReceived(false),
          style: TextButton.styleFrom(foregroundColor: colors.accent),
          child: Text('settings_easter_reopen'.tr()),
        ),
      ],
    ),
  );
}

/// 信纸配色与已确认的设计稿一致；不覆盖应用其余页面的主题。
class _LetterColors {
  const _LetterColors(this.dark);
  final bool dark;
  Color get background => Color(dark ? 0xFF19181E : 0xFFF4F3F8);
  Color get paper => Color(dark ? 0xFF222128 : 0xFFFFFEFA);
  Color get ink => Color(dark ? 0xFFEEE9E4 : 0xFF343143);
  Color get body => Color(dark ? 0xFFC1BAC7 : 0xFF656171);
  Color get muted => Color(dark ? 0xFFA39AAA : 0xFF726C7C);
  Color get line => Color(dark ? 0xFF3C3744 : 0xFFE7E3ED);
  Color get accent => Color(dark ? 0xFFC8B9DD : 0xFF696080);
  Color get soft => Color(dark ? 0xFF302B38 : 0xFFF0EDF5);
  Color get button => Color(dark ? 0xFFCABDDD : 0xFF625876);
  Color get buttonInk => Color(dark ? 0xFF28222F : 0xFFFFFEFA);
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter(this.ink, this.paper, this.soft);
  final Color ink;
  final Color paper;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 90, size.height / 80);
    final outline = Paint()
      ..color = ink.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;
    final envelope = Path()
      ..moveTo(13, 32)
      ..lineTo(44, 11)
      ..lineTo(76, 32)
      ..lineTo(76, 65)
      ..lineTo(13, 65)
      ..close();
    canvas.drawPath(envelope, Paint()..color = soft);
    canvas.drawPath(envelope, outline);
    final letter = Path()
      ..moveTo(25, 40)
      ..lineTo(25, 20)
      ..lineTo(64, 20)
      ..lineTo(64, 42);
    canvas.drawPath(letter, Paint()..color = paper);
    canvas.drawPath(letter, outline);
    canvas.drawPath(
      Path()
        ..moveTo(34, 28)
        ..lineTo(55, 28)
        ..moveTo(34, 35)
        ..lineTo(50, 35),
      Paint()
        ..color = ink.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13, 32)
        ..lineTo(44, 54)
        ..lineTo(76, 32)
        ..moveTo(13, 65)
        ..lineTo(36, 47)
        ..moveTo(76, 65)
        ..lineTo(53, 47),
      outline,
    );
    final heart = Path()
      ..moveTo(44, 44)
      ..cubicTo(38, 36, 34, 44, 44, 50)
      ..cubicTo(54, 44, 50, 36, 44, 44)
      ..close();
    canvas.drawPath(heart, Paint()..color = ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.soft != soft;
}
