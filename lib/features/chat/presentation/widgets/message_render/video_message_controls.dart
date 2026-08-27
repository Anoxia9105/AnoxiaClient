import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

class VideoMessageControlPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const VideoMessageControlPill({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: HugeIcon(icon: icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class VideoMessageFullscreenPage extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;

  const VideoMessageFullscreenPage({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.white24,
        onPressed: () {
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, value, _) => HugeIcon(
            icon: value.isPlaying
                ? HugeIcons.strokeRoundedPause
                : HugeIcons.strokeRoundedPlay,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
