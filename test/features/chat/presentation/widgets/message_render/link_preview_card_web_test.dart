@TestOn('browser')
library;

import 'package:anoxia/features/chat/presentation/widgets/message_render/link_preview_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web metadata loading falls back without creating a ReceivePort',
    () async {
      const link = 'https://preview.invalid/web-fallback';

      final metadata = await MessageLinkPreview.fetchMetadata(link);

      expect(metadata.title, 'preview.invalid');
      expect(metadata.description, link);
      expect(metadata.siteName, 'preview.invalid');
      expect(metadata.loadedRemotely, isFalse);
    },
  );
}
