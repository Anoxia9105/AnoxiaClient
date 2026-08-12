import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoView extends StatefulWidget {
  final String url;
  final bool autoplay;

  const BackgroundVideoView({
    super.key,
    required this.url,
    this.autoplay = true,
  });

  @override
  State<BackgroundVideoView> createState() => _BackgroundVideoViewState();
}

class _BackgroundVideoViewState extends State<BackgroundVideoView> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.autoplay != widget.autoplay) {
      _disposeController();
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(widget.autoplay);
      await controller.setVolume(0);
      if (widget.autoplay) {
        await controller.play();
      } else {
        await controller.seekTo(Duration.zero);
      }
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
    if (controller != null) Future<void>.microtask(controller.dispose);
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
      return const SizedBox.expand();
    }
    final size = controller.value.size;
    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
