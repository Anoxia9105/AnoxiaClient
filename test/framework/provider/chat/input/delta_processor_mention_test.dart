import 'dart:convert';

import 'package:anoxia/framework/provider/chat/input/delta_processor.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Delta deltaWithMentions({bool withAtAll = false}) {
    final delta = Delta()
      ..insert('hi ')
      ..insert({
        'mention': jsonEncode({'userId': 1, 'userName': 'alice'}),
      })
      ..insert(' ');
    if (withAtAll) {
      delta
        ..insert({
          'mention': jsonEncode({
            'userId': kMentionAllUserId,
            'userName': '所有人',
          }),
        })
        ..insert(' ');
    }
    delta.insert('\n');
    return delta;
  }

  group('DeltaProcessor @提及', () {
    test('普通提及：mentionAll 为 false，mentionedUserIds 保留真实用户', () {
      final processor = DeltaProcessor(deltaWithMentions(), const {});
      expect(processor.mentionAll, isFalse);
      expect(processor.mentionedUserIds, [1]);
    });

    test('包含 @所有人：mentionAll 为 true，占位 ID 不计入真实提醒', () {
      final processor = DeltaProcessor(
        deltaWithMentions(withAtAll: true),
        const {},
      );
      expect(processor.mentionAll, isTrue);
      expect(processor.mentionedUserIds, [1]);
    });

    test('仅 @所有人：mentionedUserIds 为空但 mentionAll 为 true', () {
      final delta = Delta()
        ..insert({
          'mention': jsonEncode({
            'userId': kMentionAllUserId,
            'userName': '所有人',
          }),
        })
        ..insert(' ')
        ..insert('\n');
      final processor = DeltaProcessor(delta, const {});
      expect(processor.mentionAll, isTrue);
      expect(processor.mentionedUserIds, isEmpty);
      expect(processor.isSingleEmoji, isFalse);
    });
  });

  group('MessagePayload @所有人', () {
    test('toTypedJson 的 interaction 携带 mentionAll', () {
      const payload = MessagePayload(
        content: 'hi',
        quillDelta: '[{"insert":"hi\\n"}]',
        mentionAll: true,
      );
      final typed = payload.toTypedJson(MessageType.richText);
      final interaction = typed['richText'] as Map;
      expect(interaction['interaction'], {
        'replyToMessageId': null,
        'mentionUserIds': null,
        'mentionAll': true,
      });
    });

    test('fromJson 从 delta 中识别 @所有人', () {
      final payload = MessagePayload.fromJson({
        'richText': {
          'plainText': 'hi',
          'deltaJson': jsonEncode([
            {
              'insert': {
                'mention': jsonEncode({
                  'userId': kMentionAllUserId,
                  'userName': '所有人',
                }),
              },
            },
          ]),
          'interaction': {
            'mentionUserIds': [1],
          },
        },
      });
      expect(payload.mentionAll, isTrue);
      expect(payload.mentions, [1]);
    });

    test('fromJson 从 interaction.mentionAll 识别 @所有人', () {
      final payload = MessagePayload.fromJson({
        'richText': {
          'plainText': 'hi',
          'deltaJson': '[{"insert":"hi\\n"}]',
          'interaction': {
            'mentionUserIds': [1],
            'mentionAll': true,
          },
        },
      });
      expect(payload.mentionAll, isTrue);
    });

    test('toFlatJson 往返保留 mentionAll', () {
      const payload = MessagePayload(
        content: 'hi',
        mentionAll: true,
        mentions: [1],
      );
      final restored = MessagePayload.fromJson(payload.toFlatJson());
      expect(restored.mentionAll, isTrue);
      expect(restored.mentions, [1]);
    });
  });

  group('MessagePayload.deltaMentionsAll', () {
    test('不含 @所有人时返回 false', () {
      expect(
        MessagePayload.deltaMentionsAll(
          jsonEncode([
            {
              'insert': {
                'mention': jsonEncode({'userId': 1, 'userName': 'alice'}),
              },
            },
          ]),
        ),
        isFalse,
      );
      expect(MessagePayload.deltaMentionsAll(null), isFalse);
      expect(MessagePayload.deltaMentionsAll('not json'), isFalse);
    });

    test('含 @所有人时返回 true', () {
      expect(
        MessagePayload.deltaMentionsAll(
          jsonEncode([
            {
              'insert': {
                'mention': jsonEncode({
                  'userId': kMentionAllUserId,
                  'userName': '所有人',
                }),
              },
            },
          ]),
        ),
        isTrue,
      );
    });
  });

  group('DeltaProcessor 视频附件', () {
    test('file embed 中的视频仅归类到 videos', () {
      const attachment = Attachment(
        id: 'video-1',
        kind: 'VIDEO',
        url: 'C:/video.mp4',
        name: 'video.mp4',
        type: 'video/mp4',
      );
      final delta = Delta()
        ..insert({'file': jsonEncode(attachment.toJson())})
        ..insert('\n');

      final processor = DeltaProcessor(delta, const {
        'video-1': 'https://example.com/video.mp4',
      });

      expect(processor.videos, hasLength(1));
      expect(processor.videos.single.url, 'https://example.com/video.mp4');
      expect(processor.images, isEmpty);
      expect(processor.files, isEmpty);
      expect(processor.isAllUploaded, isTrue);
    });

    test('视频加单个 Emoji 不会被判定为纯 Emoji 消息', () {
      const attachment = Attachment(
        id: 'video-1',
        kind: 'VIDEO',
        url: 'C:/video.mp4',
        name: 'video.mp4',
        type: 'video/mp4',
      );
      final delta = Delta()
        ..insert({'file': jsonEncode(attachment.toJson())})
        ..insert('😀')
        ..insert('\n');

      final processor = DeltaProcessor(delta, const {
        'video-1': 'https://example.com/video.mp4',
      });

      expect(processor.isSingleEmoji, isFalse);
    });
  });
}
