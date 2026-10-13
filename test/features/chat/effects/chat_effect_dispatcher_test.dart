import 'dart:convert';

import 'package:anoxia/domain/models/chat_effect_rule.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 13, 14);
  late DateTime now;
  late ChatEffectDispatcher dispatcher;
  late List<ChatEffectEvent> events;

  ChatMessage message({
    String id = 'm1',
    String? clientId = 'c1',
    String room = 'r1',
    String text = '生日快乐！',
    MessageType type = MessageType.text,
    MessagePayload? payload,
    int? timestamp,
  }) => ChatMessage(
    messageId: id,
    clientMsgId: clientId,
    roomId: room,
    messageType: type,
    content: text,
    payload: payload,
    timestamp: timestamp ?? now.millisecondsSinceEpoch,
  );

  setUp(() {
    now = start;
    dispatcher = ChatEffectDispatcher(clock: () => now);
    events = [];
    dispatcher.events.listen(events.add);
  });
  tearDown(() => dispatcher.dispose());

  test('中文祝福和英文词组命中生日，普通聊天不命中', () {
    expect(matchChatEffect(message())?.id, 'birthday');
    expect(matchChatEffect(message(text: 'HAPPY   BIRTHDAY!'))?.id, 'birthday');
    expect(matchChatEffect(message(text: 'unhappy birthdayish')), isNull);
    expect(matchChatEffect(message(text: '晚安')), isNull);
  });

  test('日语生日祝福支持汉字、假名与片假名，普通祝贺不触发', () {
    for (final text in [
      '誕生日おめでとう！',
      'お誕生日おめでとうございます🎂',
      'おたんじょうびおめでとう！',
      'ハッピーバースデー！',
    ]) {
      expect(
        matchChatEffect(message(text: text))?.id,
        'birthday',
        reason: text,
      );
    }
    expect(matchChatEffect(message(text: 'おめでとうございます')), isNull);
    expect(matchChatEffect(message(text: '明日は誕生日です')), isNull);
    expect(
      matchChatEffect(
        message(
          type: MessageType.richText,
          payload: MessagePayload(
            quillDelta: jsonEncode([
              {
                'insert': 'お誕生日',
                'attributes': {'bold': true},
              },
              {'insert': 'おめでとうございます\n'},
            ]),
          ),
        ),
      )?.id,
      'birthday',
    );
  });

  test('想你了支持中英日三语并选择星星，普通聊天不触发', () {
    for (final text in [
      '我想你了！',
      'I MISS   YOU!',
      'Miss you ❤️',
      '君に会いたいです',
      'あいたい！',
    ]) {
      final rule = matchChatEffect(message(text: text));
      expect(rule?.id, 'miss_you', reason: text);
      expect(rule?.emojis, ['⭐', '🌟', '✨']);
    }
    expect(matchChatEffect(message(text: 'dismiss yourself')), isNull);
    expect(matchChatEffect(message(text: '会いたくない')), isNull);
    expect(matchChatEffect(message(text: '想了想今天的安排')), isNull);
  });

  test('富文本想念触发星星，ACK 回显去重且同条生日按优先级播放', () {
    final richText = message(
      type: MessageType.richText,
      payload: MessagePayload(
        quillDelta: jsonEncode([
          {
            'insert': '想你',
            'attributes': {'bold': true},
          },
          {'insert': '了\n'},
        ]),
      ),
    );
    dispatcher.offer(richText, observedAt: now);
    dispatcher.offer(richText.copyWith(messageId: 'server1'), observedAt: now);
    expect(events, hasLength(1));
    expect(events.single.rule.id, 'miss_you');
    expect(matchChatEffect(message(text: '生日快乐，想你了'))?.id, 'birthday');
  });

  test('富文本仅匹配文本 insert，不匹配属性与 mention embed', () {
    final payload = MessagePayload(
      quillDelta: jsonEncode([
        {
          'insert': '生日',
          'attributes': {'bold': true},
        },
        {'insert': '快乐\n'},
      ]),
    );
    expect(
      matchChatEffect(
        message(type: MessageType.richText, payload: payload),
      )?.id,
      'birthday',
    );
    expect(
      matchChatEffect(
        message(
          type: MessageType.richText,
          payload: MessagePayload(
            quillDelta: jsonEncode([
              {
                'insert': {'mention': '生日快乐'},
              },
              {
                'insert': '你好',
                'attributes': {'link': '生日快乐'},
              },
            ]),
          ),
        ),
      ),
      isNull,
    );
    expect(
      matchChatEffect(
        message(
          type: MessageType.richText,
          payload: const MessagePayload(quillDelta: 'broken'),
        ),
      ),
      isNull,
    );
  });

  test('附件说明与转发不触发，回复只匹配本条正文', () {
    expect(matchChatEffect(message(type: MessageType.image)), isNull);
    expect(matchChatEffect(message(type: MessageType.system)), isNull);
    expect(
      matchChatEffect(
        message(
          payload: const MessagePayload(
            forwardInfo: ForwardInfo(authorName: '林间', originalTimestampMs: 1),
          ),
        ),
      ),
      isNull,
    );
    expect(
      matchChatEffect(
        message(
          payload: const MessagePayload(replyTo: '生日快乐'),
          text: '谢谢',
        ),
      ),
      isNull,
    );
    expect(
      matchChatEffect(
        message(payload: const MessagePayload(replyTo: 'old')),
      )?.id,
      'birthday',
    );
  });

  test('扩展词库无需改变分发链路', () {
    const custom = ChatEffectRule(
      id: 'newyear',
      keywords: ['新年快乐'],
      emojis: ['🎉'],
    );
    expect(
      matchChatEffect(message(text: '新年快乐'), rules: [custom]),
      same(custom),
    );
  });

  test('ACK 与回显顺序任意，客户端和服务端 ID 别名只消费一次', () {
    dispatcher.offer(message(id: 'c1'), observedAt: now);
    dispatcher.offer(message(id: 'server1'), observedAt: now);
    dispatcher.offer(message(id: 'server1', clientId: null), observedAt: now);
    expect(events, hasLength(1));
  });

  test('回显先到且注册更多别名也不会重复', () {
    dispatcher.offer(message(id: 'server1'), observedAt: now);
    dispatcher.offer(message(id: 'c1'), observedAt: now);
    expect(events, hasLength(1));
  });

  test('旧消息、缺少时间、远期时间与失败/发送中状态不触发', () {
    dispatcher.offer(
      message(
        timestamp: now
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      ),
      observedAt: now,
    );
    dispatcher.offer(
      message(
        id: 'm2',
        clientId: 'c2',
        timestamp: now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      ),
      observedAt: now,
    );
    dispatcher.offer(
      ChatMessage(
        messageId: 'm3',
        roomId: 'r1',
        content: '生日快乐',
        messageType: MessageType.text,
      ),
      observedAt: now,
    );
    dispatcher.offer(
      message(
        id: 'm4',
        clientId: 'c4',
      ).copyWith(deliveryStatus: DeliveryStatus.failed),
      observedAt: now,
    );
    expect(events, isEmpty);
  });

  test('不可见消息消费后不会在下次订阅时重放', () {
    dispatcher.dispose();
    dispatcher = ChatEffectDispatcher(clock: () => now);
    dispatcher.offer(message(), observedAt: now);
    dispatcher.events.listen(events.add);
    dispatcher.offer(message(), observedAt: now);
    expect(events, isEmpty);
  });

  test('只对真正播放的消息限频，同房间 8 秒冷却，不影响其他房间', () {
    dispatcher.offer(message(), observedAt: now);
    expect(dispatcher.claim(events.last), isTrue);
    now = now.add(const Duration(seconds: 4));
    dispatcher.offer(
      message(id: 'm2', clientId: 'c2'),
      observedAt: now,
    );
    expect(dispatcher.claim(events.last), isFalse);
    dispatcher.offer(
      message(id: 'm3', clientId: 'c3', room: 'r2'),
      observedAt: now,
    );
    expect(dispatcher.claim(events.last), isTrue);
    now = now.add(const Duration(seconds: 4));
    dispatcher.offer(
      message(id: 'm4', clientId: 'c4'),
      observedAt: now,
    );
    expect(dispatcher.claim(events.last), isTrue);
  });

  test('收到消息到落库之间跨过前后台边界仍保留原到达时间', () {
    dispatcher.offer(
      message(),
      observedAt: now.subtract(const Duration(seconds: 3)),
    );
    expect(
      events.single.observedAt,
      start.subtract(const Duration(seconds: 3)),
    );
  });
}
