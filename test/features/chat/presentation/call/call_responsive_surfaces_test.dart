import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/screen_share_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

// 共享轨已结束，仍保留真实 Listenable 行为以测试查看器的退出流程。
class _EndedSharer extends Fake implements Participant {
  final _notifier = ChangeNotifier();

  @override
  List<TrackPublication> get videoTrackPublications => [];

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);

  void disposeNotifier() => _notifier.dispose();
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('zh')],
        startLocale: const Locale('zh'),
        path: 'assets/i18n',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('共享结束后显示结束态且可退出，视口 $size', (tester) async {
      final sharer = _EndedSharer();
      addTearDown(sharer.disposeNotifier);
      await _mount(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showScreenShareViewer(context, sharer),
            child: const Text('查看共享'),
          ),
        ),
        size: size,
      );

      await tester.tap(find.text('查看共享'));
      await tester.pumpAndSettle();
      final rotation = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotation.quarterTurns, size.height > size.width ? 1 : 0);
      expect(find.byType(VideoTrackRenderer), findsNothing);
      expect(find.text('call_share_ended'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('查看共享'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320×240错误页可滚动操作且不溢出', (tester) async {
    var retries = 0;
    var cancellations = 0;
    await _mount(
      tester,
      CallErrorState(
        roomId: 'test-room',
        errorText: '连接暂时中断，请检查网络连接后重新尝试',
        detail: '网络暂时不可用，恢复网络后可以重新连接通话。' * 12,
        onRetry: () async {
          retries++;
        },
        onCancel: () async {
          cancellations++;
        },
      ),
      size: const Size(320, 240),
    );
    expect(tester.takeException(), isNull);
    final retry = find.byType(FilledButton);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retries, 1);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(cancellations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面错误页内容最大宽度360并居中', (tester) async {
    await _mount(
      tester,
      const CallErrorState(roomId: 'test-room', detail: '连接已断开'),
      size: const Size(1280, 800),
    );
    final content = tester.getRect(find.byType(SingleChildScrollView));
    expect(content.width, 360);
    expect(content.center.dx, 640);
    expect(tester.takeException(), isNull);
  });
}
