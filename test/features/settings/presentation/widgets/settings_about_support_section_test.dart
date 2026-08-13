import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_about_support_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    VoidCallback? onOpenDeveloperTribute,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SettingsAboutSupportSection(
              appVersionText: '1.2.3',
              hasAppUpdate: false,
              pageState: const SettingsPageState(),
              onCheckUpdate: () {},
              onNavigateToUpdatePage: (_) {},
              onOpenOpenSourceLicenses: () {},
              onOpenDeveloperTribute: onOpenDeveloperTribute ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('关于页按概览、联系和更多资源建立清晰分区', (tester) async {
    await tester.pumpWidget(buildSubject(size: const Size(390, 844)));

    expect(find.byKey(const Key('about-overview-card')), findsOneWidget);
    expect(find.byKey(const Key('about-contact-group')), findsOneWidget);
    expect(find.byKey(const Key('about-resource-group')), findsOneWidget);
  });

  testWidgets('支持快捷操作在宽屏并排、窄屏纵向排列', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject(size: const Size(800, 1000)));

    final sponsorWide = tester.getTopLeft(
      find.byKey(const Key('about-sponsor-action')),
    );
    final shareWide = tester.getTopLeft(
      find.byKey(const Key('about-share-action')),
    );
    expect(sponsorWide.dy, shareWide.dy);
    expect(shareWide.dx, greaterThan(sponsorWide.dx));

    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpAndSettle();

    final sponsorNarrow = tester.getTopLeft(
      find.byKey(const Key('about-sponsor-action')),
    );
    final shareNarrow = tester.getTopLeft(
      find.byKey(const Key('about-share-action')),
    );
    expect(sponsorNarrow.dx, shareNarrow.dx);
    expect(shareNarrow.dy, greaterThan(sponsorNarrow.dy));
  });

  testWidgets('版本入口可聚焦且保留七次点击彩蛋', (tester) async {
    var tributeOpenCount = 0;
    await tester.pumpWidget(
      buildSubject(
        size: const Size(390, 844),
        onOpenDeveloperTribute: () => tributeOpenCount += 1,
      ),
    );

    final versionButton = find.byKey(const Key('about-version-button'));
    expect(versionButton, findsOneWidget);
    expect(tester.widget<InkWell>(versionButton).canRequestFocus, isTrue);
    expect(tester.getSize(versionButton).height, greaterThanOrEqualTo(44));

    for (var index = 0; index < 7; index += 1) {
      await tester.tap(versionButton);
    }
    expect(tributeOpenCount, 1);
  });

  testWidgets('小屏横屏和大字体下不发生布局溢出', (tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSubject(
        size: const Size(667, 375),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
