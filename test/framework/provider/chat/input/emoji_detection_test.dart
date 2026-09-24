import 'package:anoxia/common/utils/emoji_util.dart';
import 'package:anoxia/features/chat/models/chat_message_extensions.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/text_message_strategy.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/input/delta_processor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('单个 Unicode Emoji 检测', () {
    test('支持组合 Emoji 与键帽序列', () {
      for (final emoji in [
        '🈳',
        '🈴',
        '❤️',
        '👍🏽',
        '👨‍👩‍👧‍👦',
        '🇨🇳',
        '1️⃣',
      ]) {
        expect(
          EmojiUtil.isSingleEmoji(emoji),
          isTrue,
          reason: '$emoji 应识别为单个 Emoji 字素簇',
        );
      }
    });

    test('不把普通文字、多 Emoji 或补充平面汉字识别为单个 Emoji', () {
      for (final text in ['空', 'hello', '😀😀', '𠀀']) {
        expect(EmojiUtil.isSingleEmoji(text), isFalse);
      }
    });

    test('桌面 Delta 发送链路识别方框 CJK Emoji', () {
      for (final emoji in ['🈳', '🈴']) {
        final delta = Delta()..insert('$emoji\n');

        expect(
          DeltaProcessor(delta, const {}).isSingleEmoji,
          isTrue,
          reason: '$emoji 应作为 Emoji 消息发送',
        );
      }
    });

    test('普通文字和多个 Emoji 不应识别为单个 Emoji', () {
      for (final text in ['空', 'hello', '😀😀']) {
        final delta = Delta()..insert('$text\n');

        expect(DeltaProcessor(delta, const {}).isSingleEmoji, isFalse);
      }
    });

    test('文本类型的历史单 Emoji 消息保持无气泡展示', () {
      final message = _textMessage('🈳');

      expect(message.needsBubble, isFalse);
    });

    testWidgets('文本类型的历史单 Emoji 消息按大号 Emoji 渲染', (tester) async {
      final message = _textMessage('🈳');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextMessageStrategy().buildContent(
              context,
              message,
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('🈳'));
      expect(text.style?.fontSize, 48);
      expect(text.style?.color, isNull);
    });
  });
}

ChatMessage _textMessage(String content) => ChatMessage(
  messageId: 'message-1',
  roomId: 'room-1',
  senderId: 1,
  messageType: MessageType.text,
  content: content,
  payload: MessagePayload(content: content),
);
