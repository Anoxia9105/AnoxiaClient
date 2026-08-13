import 'package:anoxia/common/widgets/app/background_video_view.dart';
import 'package:anoxia/features/settings/presentation/widgets/background_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('video thumbnail renders the video first frame without autoplay', (
    tester,
  ) async {
    const url = 'https://cdn.example.com/background.mp4';

    await tester.pumpWidget(
      const MaterialApp(home: BackgroundVideoThumbnail(url: url)),
    );

    final preview = tester.widget<BackgroundVideoView>(
      find.byType(BackgroundVideoView),
    );
    expect(preview.url, url);
    expect(preview.autoplay, isFalse);
  });
}
