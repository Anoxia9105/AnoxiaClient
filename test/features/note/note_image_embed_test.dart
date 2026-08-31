import 'dart:convert';

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
}
