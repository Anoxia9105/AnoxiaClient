import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_dialog.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_search_bar.dart';
import 'package:anoxia/framework/domain/user_vo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('搜索框使用无外层边框的轻量样式并缩小搜索图标', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddFriendSearchBar(
            controller: controller,
            isSearching: false,
            onSearch: () {},
            onClear: () {},
            onSubmitted: (_) {},
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final searchSurface = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((container) => container.constraints?.maxHeight == 52);
    final decoration = searchSurface.decoration! as BoxDecoration;
    final searchIcon = tester
        .widgetList<HugeIcon>(find.byType(HugeIcon))
        .firstWhere((icon) => icon.icon == HugeIcons.strokeRoundedSearch02);

    expect(decoration.border, isNull);
    expect(searchIcon.size, 14);
  });

  testWidgets('好友申请弹窗采用扁平结构并显示清晰的验证信息标签', (tester) async {
    final user = UserVO(
      userId: 7,
      userName: 'friend_7',
      nickName: '新朋友',
      phonenumber: '13800000000',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddFriendDialog(user: user)),
        ),
      ),
    );

    final gradients = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.gradient != null);

    expect(gradients, isEmpty);
    expect(find.text('add_friend_request_title'), findsOneWidget);
    expect(find.text('add_friend_verify_label'), findsOneWidget);
  });

  testWidgets('好友申请弹窗在小屏和大字体下仍可滚动且不溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final user = UserVO(
      userId: 8,
      userName: 'friend_with_a_long_username',
      nickName: '名字比较长的新朋友',
      phonenumber: '13800000000',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(body: AddFriendDialog(user: user)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
