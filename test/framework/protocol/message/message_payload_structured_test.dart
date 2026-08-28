import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('code interaction survives flat JSON round trip', () {
    const payload = MessagePayload(
      content: 'dart',
      code: CodePayload(code: 'void main() {}', language: 'dart'),
      replyTo: 'message-1',
      mentions: [7, 8],
      mentionAll: true,
    );

    final decoded = MessagePayload.fromJson(payload.toFlatJson());

    expect(decoded.code?.code, 'void main() {}');
    expect(decoded.replyTo, 'message-1');
    expect(decoded.mentions, [7, 8]);
    expect(decoded.mentionAll, isTrue);
  });

  test('code typed JSON contains interaction', () {
    const payload = MessagePayload(
      code: CodePayload(code: 'print(1)'),
      replyTo: 'message-2',
      mentions: [9],
      mentionAll: true,
    );

    final json = payload.toTypedJson(MessageType.codeSnippet);
    final code = json['code']! as Map<String, dynamic>;
    final interaction = code['interaction']! as Map<String, dynamic>;

    expect(interaction['replyToMessageId'], 'message-2');
    expect(interaction['mentionUserIds'], [9]);
    expect(interaction['mentionAll'], isTrue);
  });

  test('system payload preserves event code text and properties', () {
    const payload = MessagePayload(
      content: '成员已加入',
      system: SystemPayload(
        eventCode: 'USER_JOINED',
        text: '成员已加入',
        properties: {'userId': '42'},
      ),
    );

    final typed = payload.toTypedJson(MessageType.system);
    final decoded = MessagePayload.fromJson(typed);

    expect(decoded.system?.eventCode, 'USER_JOINED');
    expect(decoded.system?.text, '成员已加入');
    expect(decoded.system?.properties, {'userId': '42'});
    expect(decoded.content, '成员已加入');
  });
}
