import 'package:anoxia/features/chat/presentation/widgets/official_room_home_view.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('官方帮助在标准手机屏幕内完整展示且无需展开', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: AppBar(), body: const OfficialRoomHomeView()),
      ),
    );

    expect(
      find.image(AssetImage(Assets.images.appIconPng.path)),
      findsOneWidget,
    );
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('official_room_help_add_friend_desc'), findsOneWidget);
    expect(find.text('official_room_help_create_group_desc'), findsOneWidget);
    expect(find.text('official_room_help_message_types_desc'), findsOneWidget);
    final lastHelpItem = find.text('official_room_help_call_desc');
    expect(lastHelpItem, findsOneWidget);
    expect(tester.getBottomRight(lastHelpItem).dy, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });
}
