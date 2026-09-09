import 'package:anoxia/features/chat/presentation/widgets/official_room_home_view.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('官方页展示悬浮胶囊锚点导航与各分区', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(),
            body: const OfficialRoomHomeView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 悬浮胶囊锚点存在（测试环境无 easy_localization 时显示 key 原文）。
    expect(find.text('official_room_anchor_overview'), findsOneWidget);
    // 锚点与分区标题同文案，各出现两次（胶囊按钮 + 分区标题）。
    expect(find.text('official_room_action_title'), findsNWidgets(2));
    expect(find.text('official_room_faq_title'), findsNWidgets(2));
    // FAQ 四个折叠项存在。
    expect(find.byType(ExpansionTile), findsNWidgets(4));
    // 点击锚点可滚动且不抛异常（同文案出现两次，取后者即悬浮胶囊内的按钮；
    // 测试环境显示 key 原文较长，先横向滚出末尾按钮）。
    await tester.scrollUntilVisible(
      find.text('official_room_nav_title').last,
      100,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('official_anchor_scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('official_room_nav_title').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
