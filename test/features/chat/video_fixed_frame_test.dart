import 'package:anoxia/features/chat/presentation/widgets/message_render/video_message_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [200.0, 400.0]) {
    testWidgets('竖拍视频在 $width 宽容器内保持横向 16:9 展示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Center(
              child: SizedBox(
                width: width,
                child: const VideoMessagePlayer(
                  heroTag: 'portrait-video',
                  videoUrl: 'local-pending://capture',
                  videoWidth: 1080,
                  videoHeight: 1920,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final size = tester.getSize(find.byType(ClipRRect).first);
      expect(size.width / size.height, closeTo(16 / 9, .001));
      expect(size.width, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    });
  }
}
