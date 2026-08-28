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
  const video = Attachment(
    id: 'video-1',
    kind: 'VIDEO',
    url: 'https://example.com/video.mp4',
    name: 'video.mp4',
    type: 'video/mp4',
    thumbnailUrl: 'https://example.com/video-cover.jpg',
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
      waveform: 'AQIDBA==',
    );

    final decoded = MessagePayload.fromJson(payload.toJson());

    expect(decoded.audio?.id, audio.id);
    expect(decoded.audio?.kind, 'AUDIO');
    expect(decoded.audioDuration, 42000);
    expect(decoded.waveform, 'AQIDBA==');
    expect(decoded.mediaAttachments, hasLength(1));
  });

  test('flat video payload survives JSON round trip', () {
    const payload = MessagePayload(
      content: 'clip',
      video: video,
      audioDuration: 42000,
      replyTo: 'message-1',
      mentions: [7],
      mentionAll: true,
    );

    final decoded = MessagePayload.fromJson(payload.toJson());

    expect(decoded.video?.id, video.id);
    expect(decoded.video?.url, video.url);
    expect(decoded.video?.thumbnailUrl, video.thumbnailUrl);
    expect(decoded.audioDuration, 42000);
    expect(decoded.content, 'clip');
    expect(decoded.replyTo, 'message-1');
    expect(decoded.mentions, [7]);
    expect(decoded.mentionAll, isTrue);
    expect(decoded.mediaAttachments, hasLength(1));
  });

  test('typed nested video payload remains supported', () {
    final decoded = MessagePayload.fromJson({
      'video': {
        'video': video.toJson(),
        'durationMs': 42000,
        'caption': 'clip',
      },
    });

    expect(decoded.video?.url, video.url);
    expect(decoded.audioDuration, 42000);
    expect(decoded.content, 'clip');
  });
}
