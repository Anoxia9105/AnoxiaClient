import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/theme/app_colors.dart';

/// 通话操作按钮（挂断/接听等）
///
/// 统一挂断（危险红）与接听（成功绿）的视觉，避免各处硬编码 `Color(0xFFE53945)` / `Color(0xFF22C55E)`。
/// 背景色默认走语义色，可通过 [backgroundColor] 覆盖。
enum CallButtonVariant { hangUp, accept, neutral }

class CallActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String? label;
  final String? tooltip;
  final CallButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPressed;
  final double size;

  const CallActionButton({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    this.variant = CallButtonVariant.neutral,
    this.backgroundColor,
    this.foregroundColor,
    this.onPressed,
    this.size = 68,
  });

  const CallActionButton.hangUp({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
    this.size = 68,
  })  : variant = CallButtonVariant.hangUp,
        backgroundColor = null,
        foregroundColor = null;

  const CallActionButton.accept({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
    this.size = 68,
  })  : variant = CallButtonVariant.accept,
        backgroundColor = null,
        foregroundColor = null;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ??
        switch (variant) {
          CallButtonVariant.hangUp => appColors?.danger ?? const Color(0xFFE53945),
          CallButtonVariant.accept => appColors?.success ?? const Color(0xFF22C55E),
          CallButtonVariant.neutral => cs.primary,
        };
    final fg = foregroundColor ?? Colors.white;

    Widget button = Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: HugeIcon(icon: icon, size: 22, color: fg),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    if (label == null) return button;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 10),
        Text(label!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }
}

/// 移动端通话控制栏的小尺寸按钮（复用 CallActionButton 的语义色）
class CallControlButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String tooltip;
  final bool active;
  final bool enabled;
  final VoidCallback? onPressed;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = enabled
        ? (active ? cs.primary : cs.surfaceContainerHighest)
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = enabled
        ? (active ? cs.onPrimary : cs.onSurfaceVariant)
        : cs.onSurfaceVariant.withValues(alpha: 0.5);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox.square(
            dimension: 48,
            child: Center(child: HugeIcon(icon: icon, size: 20, color: fg)),
          ),
        ),
      ),
    );
  }
}
