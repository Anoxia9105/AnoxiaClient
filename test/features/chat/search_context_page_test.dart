import 'dart:async';

import 'package:anoxia/features/chat/presentation/widgets/search_context_message_item.dart';
import 'package:anoxia/features/chat/presentation/widgets/search_context_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/search_context_skeleton.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
}

class _Search extends SearchMessageService {
  int searches = 0;
  int before = 0;
  int after = 0;
  final pending = Completer<void>();

  @override
  Future<void> searchMessages(String roomId, String keyword) async {
    searches++;
    state = state.copyWith(
      keyword: keyword,
      messages: [
        for (var i = 0; i < 15; i++)
          ChatMessage(
            messageId: 'message-$i',
            messageType: MessageType.text,
            content: 'Message $i',
          ),
      ],
      matchIndices: [0, 14],
      totalMatches: 2,
      hasMoreBefore: true,
      hasMoreAfter: true,
    );
  }

  @override
  Future<void> loadMoreBefore(String roomId, String keyword) async {
    before++;
    state = state.copyWith(isLoading: true);
    await pending.future;
    if (ref.mounted) state = state.copyWith(isLoading: false);
  }

  @override
  Future<void> loadMoreAfter(String roomId, String keyword) async {
    after++;
  }
}

void main() {
  testWidgets('匹配箭头只定位，手动滚到边缘才补拉并展示骨架', (tester) async {
    final search = _Search();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchMessageServiceProvider.overrideWith(() => search),
          authControllerProvider.overrideWith(_Auth.new),
          roomMembersProvider('room').overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: SearchContextPage(roomId: 'room', roomName: 'Room'),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'query');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('search_context_next_match'));
    await tester.pumpAndSettle();
    expect(find.text('Message 14'), findsOneWidget);
    await tester.tap(find.byTooltip('search_context_previous_match'));
    await tester.pumpAndSettle();
    expect(find.text('Message 0'), findsOneWidget);
    expect(search.searches, 1);
    expect(search.before + search.after, 0);

    final list = find.byType(ScrollablePositionedList);
    await tester.drag(list, const Offset(0, -170));
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, 250));
    await tester.pump();
    expect(search.before, 1);
    await tester.pump();
    expect(find.byType(SearchContextSkeleton), findsOneWidget);
    expect(find.byType(SearchContextMessageItem), findsWidgets);
    search.pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SearchContextSkeleton), findsNothing);
  });
}
