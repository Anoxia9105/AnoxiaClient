import 'package:anoxia/features/settings/presentation/pages/developer_tribute_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/design_test_app.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  String language = 'zh',
  double width = 390,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  GlobalKey? captureKey,
  Widget child = const DeveloperTributePage(),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    designTestApp(
      container: container,
      child: child,
      locale: Locale(language),
      brightness: brightness,
      textScale: textScale,
      captureKey: captureKey,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('信件正文、收下和重新阅读保留完整文案', (tester) async {
    await _pumpPage(tester);
    expect(find.text('给偶然来到这里的你'), findsOneWidget);
    expect(find.text('没被看见的努力，也算数。'), findsOneWidget);
    expect(find.textContaining('seq'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('easter-accept')));
    await tester.tap(find.byKey(const Key('easter-accept')));
    await tester.pumpAndSettle();
    expect(find.text('愿重要的话，\n都有回音。'), findsOneWidget);
    expect(find.text('给偶然来到这里的你'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('easter-reopen')));
    await tester.tap(find.byKey(const Key('easter-reopen')));
    await tester.pumpAndSettle();
    expect(find.text('给偶然来到这里的你'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('返回关闭彩蛋路由，页面主题不修改应用主题', (tester) async {
    await _pumpPage(
      tester,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('open-easter'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DeveloperTributePage(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-easter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('easter-theme')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('切换浅色模式'), findsOneWidget);
    await tester.tap(find.byKey(const Key('easter-back')));
    await tester.pumpAndSettle();
    expect(find.byType(DeveloperTributePage), findsNothing);
    expect(
      Theme.of(tester.element(find.byKey(const Key('open-easter')))).brightness,
      Brightness.light,
    );
  });

  testWidgets('复制的是短句，失败有反馈，主题切换不丢失阅读状态', (tester) async {
    String? copied;
    var fail = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          if (fail) throw PlatformException(code: 'clipboard-unavailable');
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpPage(tester);
    final copy = find.byKey(const Key('easter-copy'));
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, '没被看见的努力，也算数。');
    expect(find.text('已复制，留给需要的时候。'), findsOneWidget);
    fail = true;
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(find.text('暂时无法复制，可以稍后再试。'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('easter-theme')));
    await tester.tap(find.byKey(const Key('easter-theme')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('切换浅色模式'), findsOneWidget);
    expect(find.text('给偶然来到这里的你'), findsOneWidget);
  });

  for (final language in ['zh', 'en', 'ja']) {
    for (final width in [320.0, 390.0, 900.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('彩蛋 $language $width $brightness 大字体可读', (tester) async {
          await _pumpPage(
            tester,
            language: language,
            width: width,
            brightness: brightness,
            textScale: 1.6,
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byKey(const Key('easter-copy')));
          await tester.ensureVisible(find.byKey(const Key('easter-accept')));
          await tester.tap(find.byKey(const Key('easter-accept')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('easter-reopen')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final width in [390.0, 900.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('设计预览 $width $brightness', (tester) async {
        final key = GlobalKey();
        await _pumpPage(
          tester,
          width: width,
          brightness: brightness,
          captureKey: key,
        );
        await captureDesign(tester, key, 'easter-$width-${brightness.name}');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
