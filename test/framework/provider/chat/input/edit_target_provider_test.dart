// 消息编辑判定与编辑目标状态的单测（P1-1）
//
// canEditMessage 与服务端口径一致：仅本人 + Text/RichText（富文本不带 embed）
// + 服务端同款 15 分钟窗口。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/chat/input/edit_target_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _msg({
  int? senderId,
  DeliveryStatus status = DeliveryStatus.sent,
  MessageType type = MessageType.text,
  String? messageId = 'm-1',
  int? timestamp,
  MessagePayload? payload,
  Map<String, String> properties = const {},
}) {
  return ChatMessage(
    messageId: messageId,
    clientMsgId: messageId,
    roomId: 'room-1',
    senderId: senderId,
    messageType: type,
    payload: payload,
    timestamp: timestamp,
    properties: properties,
    deliveryStatus: status,
  );
}

void main() {
  final now = DateTime.now().millisecondsSinceEpoch;

  group('canEditMessage', () {
    test('本人的窗口内文本消息可编辑', () {
      final message = _msg(senderId: 7, timestamp: now);
      expect(canEditMessage(message, 7), isTrue);
    });

    test('他人消息不可编辑', () {
      final message = _msg(senderId: 8, timestamp: now);
      expect(canEditMessage(message, 7), isFalse);
    });

    test('未登录不可编辑', () {
      final message = _msg(senderId: 7, timestamp: now);
      expect(canEditMessage(message, null), isFalse);
    });

    test('超窗（16 分钟前）不可编辑', () {
      final message = _msg(senderId: 7, timestamp: now - 16 * 60 * 1000);
      expect(canEditMessage(message, 7), isFalse);
    });

    test('发送失败/无服务端消息 ID 的消息不可编辑', () {
      final failed = _msg(
        senderId: 7,
        timestamp: now,
        status: DeliveryStatus.failed,
      );
      final pending = _msg(
        senderId: 7,
        timestamp: now,
        messageId: null,
      );
      expect(canEditMessage(failed, 7), isFalse);
      expect(canEditMessage(pending, 7), isFalse);
    });

    test('带媒体的消息不可编辑', () {
      final image = _msg(
        senderId: 7,
        timestamp: now,
        type: MessageType.image,
        payload: const MessagePayload(content: '[image]'),
      );
      expect(canEditMessage(image, 7), isFalse);
    });

    test('富文本（纯文本+属性）可编辑', () {
      final rich = _msg(
        senderId: 7,
        timestamp: now,
        type: MessageType.richText,
        payload: const MessagePayload(
          content: 'hello',
          quillDelta: '{"ops":[{"insert":"hello"},{"insert":"\\n"}]}',
        ),
      );
      expect(canEditMessage(rich, 7), isTrue);
    });

    test('富文本带 embed（图片）不可编辑', () {
      final richWithEmbed = _msg(
        senderId: 7,
        timestamp: now,
        type: MessageType.richText,
        payload: const MessagePayload(
          content: 'hello',
          quillDelta:
              '{"ops":[{"insert":{"image":"abc"}},{"insert":"\\n"}]}',
        ),
      );
      expect(canEditMessage(richWithEmbed, 7), isFalse);
    });

    test('富文本 Delta 结构异常时保守视为不可编辑', () {
      final broken = _msg(
        senderId: 7,
        timestamp: now,
        type: MessageType.richText,
        payload: const MessagePayload(content: 'hello', quillDelta: '{oops'),
      );
      expect(canEditMessage(broken, 7), isFalse);
    });
  });

  group('ChatMessage.isEdited', () {
    test('properties 带 edited 标记即视为已编辑', () {
      final message = _msg(properties: {'edited': '1'});
      expect(message.isEdited, isTrue);
      expect(_msg().isEdited, isFalse);
    });

    test('服务端 properties JSON 字符串经 fromJson 也能解析出编辑标记', () {
      final message = ChatMessage.fromJson({
        'messageId': 'm-1',
        'roomId': 'room-1',
        'messageType': 1,
        'content': 'hello',
        'properties': '{"edited":"1"}',
      });
      expect(message.isEdited, isTrue);
    });
  });

  group('EditTargetController', () {
    test('按房间设置/清除编辑目标，互不影响其它房间', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final target = _msg();
      container
          .read(editTargetControllerProvider.notifier)
          .set('room-1', target);
      expect(container.read(editTargetProvider('room-1')), same(target));

      // clear 未设置的房间是无操作
      container.read(editTargetControllerProvider.notifier).clear('room-2');
      expect(container.read(editTargetProvider('room-1')), same(target));

      container.read(editTargetControllerProvider.notifier).clear('room-1');
      expect(container.read(editTargetProvider('room-1')), isNull);
    });
  });
}
