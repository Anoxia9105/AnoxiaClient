import 'package:anoxia/features/chat/presentation/widgets/message_render/video_message_strategy.dart';
import 'package:anoxia/common/widgets/video_first_frame_view.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flat cached video payload renders a video message', (
    tester,
  ) async {
    final payload = MessagePayload.fromJson({
      'content': '[video]',
      'audioDuration': 42000,
      'video': {
        'id': 'video-1',
        'kind': 'VIDEO',
        'url': 'https://example.com/video.mp4',
        'name': 'video.mp4',
        'type': 'video/mp4',
      },
    });
    final message = ChatMessage(
      messageId: 'message-1',
      roomId: 'room-1',
      messageType: MessageType.video,
      content: '[video]',
      payload: payload,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: VideoMessageStrategy().buildContent(
                context,
                message,
                Colors.black,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('video.mp4'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
    expect(find.byType(VideoFirstFrameView), findsNothing);
    expect(find.byType(Hero), findsNothing);
  });
}
