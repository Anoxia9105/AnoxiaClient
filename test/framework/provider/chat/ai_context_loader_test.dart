import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/ai_context_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('按需读取当前房间最近历史及旧引用附近消息，隔离其他房间', () async {
    final calls = <int?>[];
    final quote = ChatMessage(
      roomId: 'room',
      messageId: 'old',
      seq: 10,
      messageType: MessageType.text,
      content: '旧问题',
    );
    final messages = await loadChatAiContextMessages(
      roomId: 'room',
      loaded: [],
      quotedMessage: quote,
      readHistory: ({required limit, beforeSeq}) async {
        calls.add(beforeSeq);
        return [quote, ChatMessage(roomId: 'other', content: '不得混入其他房间')];
      },
    );
    expect(calls, [null, 13]);
    expect(messages.map((m) => m.messageId), ['old']);
  });
  test('本地读取失败降级已加载内容，不清空或写回消息状态', () async {
    final message = ChatMessage(roomId: 'room', messageId: 'a', content: '已加载');
    final result = await loadChatAiContextMessages(
      roomId: 'room',
      loaded: [message],
      readHistory: ({required limit, beforeSeq}) async =>
          throw StateError('offline'),
    );
    expect(result, [message]);
  });
}
