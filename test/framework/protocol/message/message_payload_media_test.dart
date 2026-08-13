import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const image = Attachment(
    id: 'image-1',
    kind: 'IMAGE',
    url: 'https://example.com/image.png',
    name: 'image.png',
    type: 'image/png',
  );
  const file = Attachment(
    id: 'file-1',
    kind: 'FILE',
    url: 'https://example.com/document.pdf',
    name: 'document.pdf',
    type: 'application/pdf',
  );

  test('flat image payload survives JSON round trip', () {
    const payload = MessagePayload(content: '[image]', image: image);

    final decoded = MessagePayload.fromJson(payload.toJson());

    expect(decoded.image?.id, image.id);
    expect(decoded.image?.url, image.url);
    expect(decoded.mediaAttachments, hasLength(1));
  });

  test('flat file payload survives JSON round trip', () {
    const payload = MessagePayload(content: '[file]', file: file);

    final decoded = MessagePayload.fromJson(payload.toJson());

    expect(decoded.file?.id, file.id);
    expect(decoded.file?.url, file.url);
    expect(decoded.mediaAttachments, hasLength(1));
  });

  test('typed nested image and file payloads remain supported', () {
    final decodedImage = MessagePayload.fromJson({
      'image': {'image': image.toJson(), 'caption': 'photo'},
    });
    final decodedFile = MessagePayload.fromJson({
      'file': {'file': file.toJson(), 'caption': 'document'},
    });

    expect(decodedImage.image?.url, image.url);
    expect(decodedImage.content, 'photo');
    expect(decodedFile.file?.url, file.url);
    expect(decodedFile.content, 'document');
  });

  test('flat audio payload keeps duration through JSON round trip', () {
    const audio = Attachment(
      id: 'audio-1',
      kind: 'AUDIO',
      url: 'https://example.com/voice.ogg',
      name: 'voice.ogg',
      type: 'audio/ogg',
    );
    const payload = MessagePayload(
      content: '[audio]',
      audio: audio,
      audioDuration: 42000,
    );

    final decoded = MessagePayload.fromJson(payload.toJson());

    expect(decoded.audio?.id, audio.id);
    expect(decoded.audio?.kind, 'AUDIO');
    expect(decoded.audioDuration, 42000);
    expect(decoded.mediaAttachments, hasLength(1));
  });
}
