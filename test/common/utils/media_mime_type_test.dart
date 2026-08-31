import 'package:anoxia/common/utils/media_mime_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps common file extensions to real MIME types', () {
    expect(mediaMimeTypeForName('note.pdf'), 'application/pdf');
    expect(mediaMimeTypeForName('notes.txt'), 'text/plain');
    expect(mediaMimeTypeForName('photo.jpg'), 'image/jpeg');
  });

  test('uses a safe binary MIME type for unknown extensions', () {
    expect(mediaMimeTypeForName('archive.unknown'), 'application/octet-stream');
  });
}
