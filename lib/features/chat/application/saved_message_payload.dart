import 'package:anoxia/framework/protocol/message/message_payload.dart';

/// 复用收藏正文，剥离来源会话的回复、提及和转发上下文。
MessagePayload savedMessagePayload(MessagePayload source) => MessagePayload(
  content: source.content,
  quillDelta: source.quillDelta,
  markdown: source.markdown,
  emojiCode: source.emojiCode,
  audioDuration: source.audioDuration,
  image: source.image,
  audio: source.audio,
  video: source.video,
  cover: source.cover,
  file: source.file,
  asset: source.asset,
  waveform: source.waveform,
  location: source.location,
  card: source.card,
  code: source.code,
);
