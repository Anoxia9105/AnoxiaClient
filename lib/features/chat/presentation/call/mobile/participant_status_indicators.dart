import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 状态指示胶囊
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.child,
    required this.color,
    required this.compact,
  });

  final Widget child;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 23 : 28,
      height: compact ? 20 : 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}

/// 说话波形动画指示器
class SpeakingWaves extends StatelessWidget {
  const SpeakingWaves({super.key, required this.progress, required this.compact});

  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (index) {
        final phase = (progress + index * 0.24) % 1.0;
        return Container(
          width: compact ? 2 : 2.5,
          height: (compact ? 5 : 7) + phase * (compact ? 5 : 7),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(RadiusToken.sm),
          ),
        );
      }),
    );
  }
}

/// 连接质量图标
///
/// 服务端质量优先；[estimated] 为 true 表示当前为本地下行估算兜底，
/// tooltip 会追加估算弱提示。
class ConnectionQualityIcon extends StatelessWidget {
  const ConnectionQualityIcon({
    super.key,
    required this.quality,
    required this.compact,
    this.estimated = false,
  });

  final ConnectionQuality quality;
  final bool compact;
  final bool estimated;

  String _label() {
    final String base = switch (quality) {
      ConnectionQuality.excellent => 'call_quality_excellent'.tr(),
      ConnectionQuality.good => 'call_quality_good'.tr(),
      ConnectionQuality.poor => 'call_quality_poor'.tr(),
      ConnectionQuality.lost => 'call_quality_lost'.tr(),
      _ => 'call_quality_unknown'.tr(),
    };
    if (estimated && quality != ConnectionQuality.unknown) {
      return '$base${'call_quality_estimated_suffix'.tr()}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final (color, bars) = switch (quality) {
      ConnectionQuality.excellent => (const Color(0xFF42D392), 3),
      ConnectionQuality.good => (const Color(0xFF7BD88F), 3),
      ConnectionQuality.poor => (const Color(0xFFFFB454), 2),
      ConnectionQuality.lost => (const Color(0xFFE45B64), 1),
      _ => (Colors.white54, 1),
    };
    return Tooltip(
      message: _label(),
      child: Container(
        height: compact ? 20 : 24,
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            final level = index + 1;
            return Container(
              width: compact ? 2 : 2.5,
              height: (compact ? 4 : 5) + level * (compact ? 2 : 2.5),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: level <= bars ? color : Colors.white24,
                borderRadius: BorderRadius.circular(RadiusToken.sm),
              ),
            );
          }),
        ),
      ),
    );
  }
}