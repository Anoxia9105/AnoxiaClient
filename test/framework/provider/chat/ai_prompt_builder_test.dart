// P0-3 AI 消息工具 prompt 组装与文本提取纯函数测试。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage msg(MessageType type, String content, {MessagePayload? payload}) =>
    ChatMessage(
      messageId: 'm',
      clientMsgId: 'c',
      roomId: 'r',
      senderId: 1,
      messageType: type,
      content: content,
      payload: payload,
    );

void main() {
  group('messagePlainText', () {
    test('text：content 直取', () {
      expect(messagePlainText(msg(MessageType.text, '你好')), '你好');
    });

    test('richText：优先 payload.content（plainText）', () {
      final m = msg(
        MessageType.richText,
        '原始 content',
        payload: const MessagePayload(content: 'plain 文本'),
      );
      expect(messagePlainText(m), 'plain 文本');
    });

    test('历史 content 是 Quill Delta JSON → 展平 insert 文本', () {
      final m = msg(
        MessageType.richText,
        '[{"attributes":{},"insert":"第一行\\n"},{"insert":"第二"}]',
      );
      expect(messagePlainText(m), '第一行\n第二');
    });

    test('非 Delta JSON 原样返回', () {
      expect(messagePlainText(msg(MessageType.text, '[{不是 json}]')),
          '[{不是 json}]');
      expect(messagePlainText(msg(MessageType.text, '  ')), '');
    });
  });

  group('isTranslatableMessage', () {
    test('text/richText/codeSnippet 且文本非空 → true', () {
      expect(isTranslatableMessage(msg(MessageType.text, 'hi')), isTrue);
      expect(isTranslatableMessage(msg(MessageType.richText, 'hi')), isTrue);
      expect(isTranslatableMessage(msg(MessageType.codeSnippet, 'x=1')), isTrue);
    });

    test('媒体/其它类型或空文本 → false', () {
      expect(isTranslatableMessage(msg(MessageType.image, '[{json}]')), isFalse);
      expect(isTranslatableMessage(msg(MessageType.file, 'a.pdf')), isFalse);
      expect(isTranslatableMessage(msg(MessageType.text, '')), isFalse);
      expect(isTranslatableMessage(msg(MessageType.text, '   ')), isFalse);
    });
  });

  group('collectUnreadSummaryDraft', () {
    test('文本分行收、其它类型计数', () {
      final draft = collectUnreadSummaryDraft([
        msg(MessageType.text, '第一条'),
        msg(MessageType.image, ''),
        msg(MessageType.video, ''),
        msg(MessageType.richText, '', payload: const MessagePayload(content: '富文本内容')),
        msg(MessageType.file, 'document.pdf'),
        msg(MessageType.text, '   '),
      ]);
      expect(draft.lines, ['第一条', '富文本内容']);
      expect(draft.otherCount, 4);
    });

    test('媒体-only 房间：无文本行、全部计数', () {
      final draft = collectUnreadSummaryDraft([
        msg(MessageType.image, ''),
        msg(MessageType.audio, ''),
      ]);
      expect(draft.isEmpty, isTrue);
      expect(draft.otherCount, 2);
    });

    test('空列表 → 空草稿', () {
      final draft = collectUnreadSummaryDraft(const []);
      expect(draft.isEmpty, isTrue);
      expect(draft.otherCount, 0);
    });
  });

  group('buildTranslatePrompt', () {
    test('语言与原文注入到位', () {
      final p = buildTranslatePrompt('hello', language: '简体中文');
      expect(p, contains('简体中文'));
      expect(p, contains('hello'));
      expect(p.startsWith('请把'), isTrue);
    });
  });

  group('buildUnreadSummaryPrompt', () {
    test('要点要求、统计行、文本行', () {
      final prompt = buildUnreadSummaryPrompt(
        const UnreadSummaryDraft(lines: ['a', 'b'], otherCount: 3),
        language: '简体中文',
      );
      expect(prompt, contains('简体中文'));
      expect(prompt, contains('3 条图片/文件/语音'));
      expect(prompt, contains('- a'));
      expect(prompt, contains('- b'));
    });

    test('media-only：无统计行时不出空括号', () {
      final prompt = buildUnreadSummaryPrompt(
        const UnreadSummaryDraft(lines: ['a'], otherCount: 0),
        language: 'English',
      );
      expect(prompt, isNot(contains('另')));
    });

    test('超限行数：只保留最新 maxLines 并注明省略条数', () {
      final lines = [for (var i = 1; i <= 12; i++) '第$i条'];
      final prompt = buildUnreadSummaryPrompt(
        UnreadSummaryDraft(lines: lines, otherCount: 0),
        language: '简体中文',
        maxLines: 5,
      );
      expect(prompt, contains('更早的 7 条文本已省略'));
      expect(prompt, contains('- 第12条'));
      expect(prompt, contains('- 第8条'));
      expect(prompt, isNot(contains('- 第7条')));
    });
  });

  group('aiLanguageName', () {
    test('三语在同一映射；未知回退原码', () {
      expect(aiLanguageName('zh'), '简体中文');
      expect(aiLanguageName('en'), 'English');
      expect(aiLanguageName('ja'), '日本語');
      expect(aiLanguageName('ko'), 'ko');
    });
  });
}
