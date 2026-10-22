import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_status_indicators.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  for (final status in DeliveryStatus.values) {
    testWidgets('发送状态 $status：成功后无回执，发送中及失败仍可见', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageStatusIndicators(
                message: ChatMessage(deliveryStatus: status),
                isCurrentUser: true,
                isMentionedMe: false,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byType(CircularProgressIndicator),
        status == DeliveryStatus.sending ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(HugeIcon),
        status == DeliveryStatus.failed ? findsOneWidget : findsNothing,
      );
      expect(find.byType(Text), findsNothing);
      if (status == DeliveryStatus.sent) {
        expect(find.byType(Padding), findsNothing);
      }
    });
  }
  testWidgets('成功消息仍保留 @提及提示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageStatusIndicators(
            message: ChatMessage(),
            isCurrentUser: false,
            isMentionedMe: true,
          ),
        ),
      ),
    );
    expect(find.text('@'), findsOneWidget);
  });
  test('成员接口忽略旧版对端阅读水位，不再序列化回执字段', () {
    final member = ChatRoomMemberVO.fromJson({'userId': 2, 'lastReadSeq': 100});
    expect(member.userId, 2);
    expect(member.toJson().containsKey('lastReadSeq'), isFalse);
  });
}
