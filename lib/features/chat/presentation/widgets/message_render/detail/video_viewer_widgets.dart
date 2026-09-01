import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 统一的时间格式化：`mm:ss` 或 `hh:mm:ss`，零时长返回 `--:--`。
String formatVideoDuration(Duration duration) {
  if (duration == Duration.zero || duration.isNegative) return '--:--';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$seconds';
  return '$minutes:$seconds';
}

/// 底部播放控制栏：播放/暂停、静音、进度条、当前/总时长。
class VideoControlBar extends StatelessWidget {
  final bool initialized;
  final bool isPlaying;
  final bool isMuted;
  final bool hasError;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VideoPlayerController? controller;
  final Color surfaceColor;

  const VideoControlBar({
    required this.initialized,
    required this.isPlaying,
    required this.isMuted,
    required this.hasError,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.controller,
    this.surfaceColor = Colors.black54,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final duration = controller?.value.duration ?? Duration.zero;
    final screenW = MediaQuery.sizeOf(context).width;
    final maxBarW = (screenW - 32).clamp(120.0, 520.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
      ),
      constraints: BoxConstraints(maxWidth: maxBarW),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              VideoControlButton(
                icon: hasError
                    ? HugeIcons.strokeRoundedRefresh
                    : isPlaying && initialized
                    ? HugeIcons.strokeRoundedPause
                    : HugeIcons.strokeRoundedPlay,
                label: hasError ? 'retry'.tr() : null,
                onTap: onTogglePlay,
              ),
              if (initialized)
                VideoControlButton(
                  icon: isMuted
                      ? HugeIcons.strokeRoundedVolumeMute01
                      : HugeIcons.strokeRoundedVolumeHigh,
                  label: null,
                  onTap: onToggleMute,
                ),
            ],
          ),
          if (initialized && duration != Duration.zero) ...[
            const SizedBox(height: 4),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller!,
              builder: (context, value, _) {
                final pos = value.position;
                final total = value.duration;
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      formatVideoDuration(pos),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.white.withValues(alpha: 0.35),
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatVideoDuration(total),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// 播放控制按钮（公开版本）
class VideoControlButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String? label;
  final VoidCallback onTap;
  const VideoControlButton({required this.icon, this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 22, color: Colors.white),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
