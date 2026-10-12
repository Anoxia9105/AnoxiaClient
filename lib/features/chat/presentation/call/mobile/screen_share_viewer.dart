import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 在页面内部旋转，兼容手机浏览器不支持锁定系统横屏的情况。
Future<void> showScreenShareViewer(BuildContext context, Participant sharer) =>
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _ScreenShareViewer(sharer: sharer),
    );

class _ScreenShareViewer extends StatelessWidget {
  const _ScreenShareViewer({required this.sharer});
  final Participant sharer;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: LayoutBuilder(
      builder: (context, constraints) => RotatedBox(
        quarterTurns: constraints.maxHeight > constraints.maxWidth ? 1 : 0,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: sharer,
            builder: (context, _) {
              final track = sharer.videoTrackPublications
                  .where((p) => p.isScreenShare && !p.muted)
                  .map((p) => p.track)
                  .whereType<VideoTrack>()
                  .firstOrNull;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (track != null)
                    InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: VideoTrackRenderer(
                        track,
                        fit: VideoViewFit.contain,
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        'call_share_ended'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'call_share_exit_landscape'.tr(),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.fullscreen_exit),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
