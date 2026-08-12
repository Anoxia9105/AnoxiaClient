import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoThumbnail extends StatefulWidget {
  final String url;

  const BackgroundVideoThumbnail({super.key, required this.url});

  @override
  State<BackgroundVideoThumbnail> createState() =>
      _BackgroundVideoThumbnailState();
}

class _BackgroundVideoThumbnailState extends State<BackgroundVideoThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
      if (mounted) setState(() {});
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      Future<void>.microtask(controller.dispose);
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedVideo01,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
      );
    }
    final size = controller.value.size;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
