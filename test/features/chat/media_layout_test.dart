import 'package:anoxia/features/chat/presentation/widgets/message_render/image_render_metrics.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/video_message_player.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('相机图片优先使用实际解码后的方向和尺寸', () {
    final size = resolveImageMessageDisplaySize(
      const Attachment(width: 4000, height: 3000),
      intrinsicWidth: 3000,
      intrinsicHeight: 4000,
    );
    expect(size, const Size(240, 320));
  });

  test('无效协议尺寸仍使用解码尺寸', () {
    expect(
      resolveImageMessageDisplaySize(
        const Attachment(width: 0, height: 0),
        intrinsicWidth: 600,
        intrinsicHeight: 300,
      ),
      const Size(320, 160),
    );
  });

  testWidgets('窄屏横向视频保持比例且没有溢出', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: VideoMessagePlayer(
                heroTag: 'video',
                videoUrl: 'local-pending://capture',
                videoWidth: 1920,
                videoHeight: 1080,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final clip = find.byType(ClipRRect);
    final size = tester.getSize(clip.first);
    expect(size.width / size.height, closeTo(16 / 9, .001));
    expect(size.width, lessThanOrEqualTo(200));
  });
}
