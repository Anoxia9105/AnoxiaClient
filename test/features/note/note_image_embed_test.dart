import 'dart:convert';
import 'dart:typed_data';

import 'package:anoxia/features/note/presentation/widgets/note_image_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps legacy URL-only image embeds readable', () {
    expect(
      decodeNoteImageData('https://example.test/legacy.png'),
      {'url': 'https://example.test/legacy.png'},
    );
  });

  test('updates the matching note image without changing adjacent images', () {
    final document = Document.fromJson([
      {'insert': {'image': jsonEncode({'id': 'first', 'url': ''})}},
      {'insert': '\n'},
      {'insert': {'image': jsonEncode({'id': 'second', 'url': ''})}},
      {'insert': '\n'},
    ]);
    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    expect(
      updateNoteImageEmbed(controller, 'second', {
        'url': 'https://example.test/image.png',
        'width': 280.0,
      }),
      isTrue,
    );

    final images = controller.document
        .toDelta()
        .toList()
        .where((operation) => operation.data is Map)
        .map((operation) => decodeNoteImageData((operation.data as Map)['image']))
        .toList();
    final first = images.singleWhere((image) => image['id'] == 'first');
    final second = images.singleWhere((image) => image['id'] == 'second');
    expect(first['url'], isEmpty);
    expect(second['url'], 'https://example.test/image.png');
    expect(second['width'], 280.0);
  });

  test('clamps resized images to editor bounds while preserving ratio', () {
    expect(noteImageResize(400, 200, 1000, maxWidth: 640), (640.0, 320.0));
    expect(noteImageResize(400, 200, -1000, maxWidth: 640), (120.0, 60.0));
  });

  test('adaptive display uses natural size and only shrinks to fit', () {
    // 小图不放大，原尺寸展示
    expect(
      resolveNoteImageDisplaySize(
        intrinsicWidth: 100,
        intrinsicHeight: 60,
        maxWidth: 640,
      ),
      const Size(100, 60),
    );
    // 大图等比缩小到编辑器宽度
    expect(
      resolveNoteImageDisplaySize(
        intrinsicWidth: 1280,
        intrinsicHeight: 720,
        maxWidth: 640,
      ),
      const Size(640, 360),
    );
    // 用户拖过的尺寸优先于自然尺寸
    expect(
      resolveNoteImageDisplaySize(
        storedWidth: 200,
        storedHeight: 100,
        intrinsicWidth: 1280,
        intrinsicHeight: 720,
        maxWidth: 640,
      ),
      const Size(200, 100),
    );
    // 宽高缺失时用占位尺寸，且不超过编辑器宽度
    expect(
      resolveNoteImageDisplaySize(maxWidth: 640),
      const Size(320, 220),
    );
    expect(
      resolveNoteImageDisplaySize(maxWidth: 160),
      const Size(160, 110),
    );
  });

  test('decoding invalid image bytes reports unknown size', () async {
    final size = await decodeNoteImageBytesSize(
      Uint8List.fromList(List<int>.filled(16, 0x89)),
    );
    expect(size, (null, null));
  });

  test('decoding real png bytes reports natural size', () async {
    // 1x1 透明 PNG
    const base64Png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    final size = await decodeNoteImageBytesSize(
      Uint8List.fromList(base64Decode(base64Png)),
    );
    expect(size, (1.0, 1.0));
  });
}
