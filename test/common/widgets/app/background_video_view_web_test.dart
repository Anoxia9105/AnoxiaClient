import 'package:anoxia/common/widgets/app/background_video_view_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  test('背景视频禁用浏览器媒体悬浮控件', () {
    final video = web.document.createElement('video') as web.HTMLVideoElement;

    configureBackgroundVideoElement(
      video,
      url: 'https://cdn.example.com/background.mp4',
      autoplay: true,
    );

    expect(video.controls, isFalse);
    expect(video.hasAttribute('disablepictureinpicture'), isTrue);
    expect(video.hasAttribute('disableremoteplayback'), isTrue);
    expect(
      video.getAttribute('controlslist'),
      'nodownload noplaybackrate noremoteplayback nofullscreen',
    );
    expect(video.style.pointerEvents, 'none');
  });
}
