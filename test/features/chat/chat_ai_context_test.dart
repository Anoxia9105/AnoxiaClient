import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/chat_ai_assist_core.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/chat_ai_assist_widgets.dart';

void main() {
  test('旧引用关联的前后文优先于无关闲聊，并保留回复关系', () {
    final messages = List.generate(
      80,
      (i) => ChatMessage(
        roomId: 'room',
        messageId: 'm$i',
        messageType: MessageType.text,
        content: i == 1 ? '地点是东门' : '闲聊 $i ${'x' * 100}',
      ),
    );
    final input = buildSmartReplyInput(
      messages,
      roomId: 'room',
      draft: '',
      language: 'zh',
      quotedMessage: messages[2],
    );
    expect(input['conversation'], contains('地点是东门'));
    expect(input['conversation']!.length, lessThanOrEqualTo(6000));
  });
  test('上下文截断不拆分 emoji，字符预算与服务端一致', () {
    expect(clipChatAiText('😀😀a', 3), '😀');
    expect(clipChatAiText('😀😀a', 4), '😀😀');
    expect(clipChatAiText('abc', 0), '');
  });
  test('智能回复优先保留草稿与引用，并隔离会话及控制字段大小', () {
    final quoted = ChatMessage(
      roomId: 'room',
      senderId: 2,
      messageType: MessageType.text,
      content: '周六见吗？',
    );
    final input = buildSmartReplyInput(
      [
        ChatMessage(
          roomId: 'other',
          messageType: MessageType.text,
          content: '其他房间秘密',
        ),
        ChatMessage(
          roomId: 'room',
          messageType: MessageType.text,
          content: '周末安排',
        ),
      ],
      roomId: 'room',
      myUserId: '1',
      draft: '周六不方便',
      quotedMessage: quoted,
      language: 'zh',
    );
    expect(input['draft'], '周六不方便');
    expect(input['quotedMessage'], contains('周六见吗'));
    expect(input['conversation'], contains('周末安排'));
    expect(input['conversation'], isNot(contains('其他房间秘密')));
    final longInput = buildSmartReplyInput(
      [],
      roomId: 'room',
      draft: '字' * 3000,
      quotedMessage: quoted,
      language: 'fr',
    );
    expect(longInput['draft']!.length, lessThanOrEqualTo(2000));
    expect(longInput['language'], 'en');
  });

  testWidgets('双端内置动作不包含自定义，窄屏无溢出且可以操作', (tester) async {
    expect(chatAiAssistActions, hasLength(5));
    expect(chatAiAssistActions, isNot(contains(ChatAiAction.custom)));
    ChatAiAction? selected;
    for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatAiAssistActionRow(
                  selected: null,
                  onSelect: (action) => selected = action,
                ),
                ChatAiAssistActionGrid(
                  selected: null,
                  onSelect: (action) => selected = action,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byType(ChatAiAssistActionChip).first);
      expect(selected, ChatAiAction.polish);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  test('上下文保留多轮顺序、自己与不同发言者，排除媒体', () {
    final context = buildChatAiContext([
      ChatMessage(senderId: 2, messageType: MessageType.text, content: '周末去哪里'),
      ChatMessage(senderId: 1, messageType: MessageType.text, content: '想去海边'),
      ChatMessage(senderId: 3, messageType: MessageType.text, content: '几点出发'),
      ChatMessage(content: 'media-secret'),
    ], myUserId: '1');
    expect(context, contains('ME'));
    expect(context, contains('USER_2'));
    expect(context, contains('USER_3'));
    expect(context.indexOf('周末'), lessThan(context.indexOf('海边')));
    expect(context, isNot(contains('media-secret')));
  });

  test('上下文优先保留最新记录并限制大小', () {
    final context = buildChatAiContext(
      List.generate(
        60,
        (i) => ChatMessage(
          messageType: MessageType.text,
          content: 'message-$i ${'a' * 200}',
        ),
      ),
    );
    expect(context.length, lessThanOrEqualTo(2400));
    expect(context, contains('message-59'));
    expect(context, isNot(contains('message-0 ')));
  });

  test('续写仅输出新增文字，翻译使用目标语言', () {
    expect(
      buildChatEditInstruction('continueWrite'),
      contains('only the new continuation'),
    );
    expect(
      buildChatEditInstruction('translate', targetLang: '日本語'),
      contains('日本語'),
    );
    expect(buildChatEditInstruction('expand'), contains('not filler'));
    for (final action in [
      'polish',
      'expand',
      'continueWrite',
      'translate',
      'simplify',
    ]) {
      expect(buildChatEditInstruction(action).length, lessThanOrEqualTo(1000));
    }
  });
}
