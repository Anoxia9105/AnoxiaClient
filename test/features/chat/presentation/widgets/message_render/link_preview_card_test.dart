import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/message_render/link_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageLinkPreview', () {
    test('extracts and normalizes the first safe URL', () {
      expect(
        MessageLinkPreview.extractFirstUrl('visit www.example.com/path.'),
        'https://www.example.com/path',
      );
      expect(
        MessageLinkPreview.extractFirstUrl(
          'https://example.com/a then https://b.dev',
        ),
        'https://example.com/a',
      );
    });

    test('rejects text without an HTTP URL', () {
      expect(MessageLinkPreview.extractFirstUrl('hello world'), isNull);
      expect(MessageLinkPreview.extractFirstUrl('ftp://example.com'), isNull);
    });

    testWidgets('shows a fallback immediately and upgrades remote metadata', (
      tester,
    ) async {
      final metadata = Completer<LinkPreviewMetadata>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageLinkPreview(
              text: 'https://fanyi.sogou.com/text',
              metadataLoader: (_) => metadata.future,
            ),
          ),
        ),
      );

      expect(find.text('fanyi.sogou.com'), findsOneWidget);
      expect(find.text('https://fanyi.sogou.com/text'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      metadata.complete(
        const LinkPreviewMetadata(
          title: '搜狗翻译',
          description: '文本翻译服务',
          siteName: '搜狗',
          loadedRemotely: true,
        ),
      );
      await tester.pump();

      expect(find.text('搜狗翻译'), findsOneWidget);
      expect(find.text('文本翻译服务'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('fetches and parses metadata in a background isolate', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final body = utf8.encode('''
            <html><head>
              <meta property="og:title" content="Remote title">
              <meta property="og:description" content="Remote description">
              <meta property="og:image" content="data:image/png;base64,broken">
            </head></html>
          ''');
        request.response.headers.contentType = ContentType.html;
        request.response.contentLength = body.length;
        request.response.add(body);
        await request.response.close();
      });
      final link = 'http://127.0.0.1:${server.port}/preview';

      final metadata = await MessageLinkPreview.fetchMetadata(link);

      expect(metadata.title, 'Remote title');
      expect(metadata.description, 'Remote description');
      expect(metadata.imageUrl, isNull);
      expect(metadata.loadedRemotely, isTrue);
    });
  });
}
