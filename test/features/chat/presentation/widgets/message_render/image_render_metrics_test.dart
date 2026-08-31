import 'package:anoxia/features/chat/presentation/widgets/message_render/image_render_metrics.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveImageMessageDisplaySize', () {
    test('preserves protocol aspect ratio for landscape images', () {
      const attachment = Attachment(width: 1600, height: 900);

      final size = resolveImageMessageDisplaySize(attachment);

      expect(size.width / size.height, closeTo(16 / 9, 0.001));
      expect(size.width, 320);
    });

    test('preserves protocol aspect ratio for portrait images', () {
      const attachment = Attachment(width: 900, height: 1600);

      final size = resolveImageMessageDisplaySize(attachment);

      expect(size.width / size.height, closeTo(9 / 16, 0.001));
      expect(size.height, 320);
    });

    test('does not enlarge images smaller than the message bounds', () {
      const attachment = Attachment(width: 120, height: 80);

      expect(resolveImageMessageDisplaySize(attachment), const Size(120, 80));
    });

    test(
      'uses decoded image dimensions when protocol dimensions are absent',
      () {
        const attachment = Attachment();

        final size = resolveImageMessageDisplaySize(
          attachment,
          intrinsicWidth: 1600,
          intrinsicHeight: 900,
        );

        expect(size.width / size.height, closeTo(16 / 9, 0.001));
        expect(size.width, 320);
      },
    );
  });

  group('imageViewerScaleForScroll', () {
    test('first downward scroll zooms out from the actual initial scale', () {
      expect(
        imageViewerScaleForScroll(
          currentScale: null,
          initialScale: 0.2,
          scrollDeltaY: 1,
          minScale: 0.1,
          maxScale: 4,
        ),
        closeTo(0.16, 0.001),
      );
    });

    test('upward scroll zooms in', () {
      expect(
        imageViewerScaleForScroll(
          currentScale: 1,
          initialScale: 0.2,
          scrollDeltaY: -1,
        ),
        closeTo(1.2, 0.001),
      );
    });

    test('zero scroll delta leaves scale unchanged', () {
      expect(
        imageViewerScaleForScroll(
          currentScale: 1.5,
          initialScale: 0.2,
          scrollDeltaY: 0,
        ),
        1.5,
      );
    });
  });
}
