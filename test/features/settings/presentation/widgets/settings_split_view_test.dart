import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  List<SettingsDestination> destinations() => [
    SettingsDestination(
      title: '外观',
      subtitle: '主题、背景与字体',
      icon: HugeIcons.strokeRoundedColors,
      builder: (_) => const Text('外观详情内容'),
    ),
    SettingsDestination(
      title: '语言',
      subtitle: '选择界面显示语言',
      icon: HugeIcons.strokeRoundedLanguageSquare,
      builder: (_) => const Text('语言详情内容'),
    ),
  ];

  testWidgets('宽屏左侧仅显示图标和标题，点击后切换右侧详情', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsSplitView(destinations: destinations())),
      ),
    );

    final navigation = find.byKey(const Key('settings-navigation-list'));
    expect(
      find.descendant(of: navigation, matching: find.text('主题、背景与字体')),
      findsNothing,
    );
    expect(find.text('外观详情内容'), findsOneWidget);
    expect(find.text('主题、背景与字体'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-navigation-item-1')));
    await tester.pumpAndSettle();

    expect(find.text('语言详情内容'), findsOneWidget);
    expect(find.text('选择界面显示语言'), findsOneWidget);
    expect(find.text('外观详情内容'), findsNothing);
  });

  testWidgets('窄屏点击设置项后打开详情页并展示副标题', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsSplitView(destinations: destinations())),
      ),
    );

    expect(find.text('外观详情内容'), findsNothing);
    await tester.tap(find.byKey(const Key('settings-navigation-item-0')));
    await tester.pumpAndSettle();

    expect(find.text('外观详情内容'), findsOneWidget);
    expect(find.text('主题、背景与字体'), findsOneWidget);
  });

  testWidgets('系统关闭动画时详情切换不再播放过渡', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SettingsSplitView(destinations: destinations()),
          ),
        ),
      ),
    );

    // 使用 IndexedStack 实现即时切换，无残留与额外动效
    expect(find.byType(IndexedStack), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-navigation-item-1')));
    await tester.pump();
    expect(find.text('语言详情内容'), findsOneWidget);
  });
}
