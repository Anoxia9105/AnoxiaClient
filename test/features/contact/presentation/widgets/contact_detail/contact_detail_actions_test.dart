import 'dart:async';

import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_actions.dart';
import 'package:anoxia/framework/domain/chat_contact_detail_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRoomListService extends RoomListService {
  @override
  FutureOr<List<ChatRoomVO>> build() => [];

  @override
  Future<String?> getOrCreateRoom(int targetUserId) async =>
      targetUserId == 42 ? 'private-room-42' : null;
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  testWidgets('手机端点击发消息会进入对应的聊天详情页', (tester) async {
    final navigatorObserver = _RecordingNavigatorObserver();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomListServiceProvider.overrideWith(_FakeRoomListService.new),
        ],
        child: MaterialApp(
          navigatorObservers: [navigatorObserver],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: ContactDetailActions(
                          detail: ChatContactDetailVO(userId: 42),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('打开联系人详情'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开联系人详情'));
    await tester.pumpAndSettle();
    final detailContext = tester.element(find.byType(ContactDetailActions));
    expect(MediaQuery.sizeOf(detailContext).width, 390);
    expect(ModalRoute.of(detailContext), isA<MaterialPageRoute<void>>());
    await tester.tap(find.text('chat_send_message'));
    await tester.idle();

    final chatRoute = navigatorObserver.pushedRoutes.last;
    expect(chatRoute, isA<MaterialPageRoute<void>>());
    final chatPage = (chatRoute as MaterialPageRoute<void>).builder(
      detailContext,
    );
    expect(chatPage, isA<ChatRoomDetail>());
    expect((chatPage as ChatRoomDetail).roomId, 'private-room-42');
  });
}
