import 'package:anoxia/features/chat/presentation/pages/group_announcement_detail_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/group_announcement_banner.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('双击公告 $platform 宽度 $width 按设备模式展示详情', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentRoomProvider('room').overrideWith((ref) => null),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: GroupAnnouncementBanner(
                  roomId: 'room',
                  announcement: '测试公告',
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('测试公告'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('测试公告'));
        await tester.pumpAndSettle();

        expect(find.byType(GroupAnnouncementDetailPage), findsOneWidget);
        final useDialog = kIsWeb
            ? width > 1280
            : platform == TargetPlatform.windows;
        expect(find.byType(Dialog), useDialog ? findsOneWidget : findsNothing);
        final context = tester.element(
          find.byType(GroupAnnouncementDetailPage),
        );
        expect(
          ModalRoute.of(context),
          useDialog ? isA<PopupRoute>() : isA<PageRoute>(),
        );
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        expect(find.text('测试公告'), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
