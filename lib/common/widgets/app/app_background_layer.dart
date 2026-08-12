import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../framework/domain/app_background.dart';

class AppBackgroundLayer extends StatefulWidget {
  final AppBackgroundAsset asset;

  const AppBackgroundLayer({super.key, required this.asset});

  @override
  State<AppBackgroundLayer> createState() => _AppBackgroundLayerState();
}

class _AppBackgroundLayerState extends State<AppBackgroundLayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _loadVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AppBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _disposeController();
      _loadVideoIfNeeded();
    }
  }

  Future<void> _loadVideoIfNeeded() async {
    if (widget.asset.type != AppBackgroundMediaType.video) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.asset.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
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
    if (widget.asset.type == AppBackgroundMediaType.image) {
      return SizedBox.expand(
        child: Image.network(
          widget.asset.url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
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
