import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void configureBackgroundVideoElement(
  web.HTMLVideoElement video, {
  required String url,
  required bool autoplay,
}) {
  video
    ..src = url
    ..muted = true
    ..loop = autoplay
    ..autoplay = autoplay
    ..controls = false
    ..playsInline = true
    ..preload = 'auto'
    ..setAttribute('disablepictureinpicture', '')
    ..setAttribute('disableremoteplayback', '')
    ..setAttribute(
      'controlslist',
      'nodownload noplaybackrate noremoteplayback nofullscreen',
    )
    ..setAttribute('tabindex', '-1')
    ..setAttribute('aria-hidden', 'true');
  video.style
    ..width = '100%'
    ..height = '100%'
    ..objectFit = 'cover'
    ..display = 'block'
    ..pointerEvents = 'none';
}

class BackgroundVideoView extends StatelessWidget {
  final String url;
  final bool autoplay;

  const BackgroundVideoView({
    super.key,
    required this.url,
    this.autoplay = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HtmlElementView.fromTagName(
        key: ValueKey((url, autoplay)),
        tagName: 'video',
        onElementCreated: (element) {
          final video = element as web.HTMLVideoElement;
          configureBackgroundVideoElement(video, url: url, autoplay: autoplay);
          video.load();
          if (autoplay) {
            video.play().toDart.catchError((_) => null);
          }
        },
      ),
    );
  }
}
