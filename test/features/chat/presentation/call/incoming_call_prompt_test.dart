import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:anoxia/features/chat/presentation/call/component/incoming_call_prompt.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['ANOXIA_CAPTURE_UI'] != '1') return;
    await (FontLoader(
      'NotoSansSC',
    )..addFont(rootBundle.load('assets/fonts/NotoSansSC[wght].ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  const invitation = CallInvitationState(
    inviteId: 'invite',
    roomId: 'room',
    title: 'Room',
    callerName: 'Alex Chen · Design team',
    createdAt: 0,
    phase: CallInvitationPhase.incoming,
    initialMedia: CallInitialMedia.video,
  );
  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(1280, 800),
    String language = 'en',
    Brightness brightness = Brightness.light,
    CallInvitationState invite = invitation,
    Future<void> Function(CallInitialMedia)? accept,
    VoidCallback? headerTap,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: [Locale(language)],
        startLocale: Locale(language),
        path: 'assets/i18n',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              fontFamily: 'NotoSansSC',
              colorSchemeSeed: Colors.teal,
              brightness: brightness,
            ),
            home: RepaintBoundary(
              key: const ValueKey('preview'),
              child: Scaffold(
                body: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        height: kToolbarHeight,
                        width: 80,
                        child: TextButton(
                          onPressed: headerTap,
                          child: const Text('window'),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IncomingCallCard(
                        invitation: invite,
                        titleBarInset: kToolbarHeight,
                        onReject: () async {},
                        onAccept: accept ?? (_) async {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('居中突出且标题栏仍能点击，背景点击不会拒绝来电', (tester) async {
    var headerClicks = 0;
    await mount(tester, headerTap: () => headerClicks++);
    final rect = tester.getRect(
      find.byKey(const ValueKey('incoming-call-card')),
    );
    expect(rect.center.dx, closeTo(640, 1));
    expect(rect.width, 360);
    expect(rect.center.dy, closeTo((800 + kToolbarHeight) / 2, 1));
    expect(rect.top, greaterThan(kToolbarHeight));
    final reject = find.byKey(const ValueKey('incoming-call-reject'));
    final rejectStyle = tester.widget<FilledButton>(reject).style!;
    expect(rejectStyle.backgroundColor!.resolve({}), const Color(0xFFD32F2F));
    expect(rejectStyle.foregroundColor!.resolve({}), Colors.white);
    expect(tester.getSize(reject).height, lessThanOrEqualTo(48));
    expect(tester.getSize(reject).width, lessThanOrEqualTo(146));
    await tester.tap(find.text('window'));
    expect(headerClicks, 1);
    await tester.tapAt(const Offset(20, 200));
    expect(find.byKey(const ValueKey('incoming-call-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.environment['ANOXIA_CAPTURE_UI'] == '1') {
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ImageByteFormat.png);
        await File(
          '.dart_tool/incoming-call-preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  for (final language in ['zh', 'en', 'ja']) {
    for (final brightness in Brightness.values) {
      testWidgets('窄窗口可滚动操作：$language / $brightness', (tester) async {
        CallInitialMedia? accepted;
        await mount(
          tester,
          size: const Size(320, 568),
          language: language,
          brightness: brightness,
          accept: (media) async {
            accepted = media;
          },
        );
        final voice = find.widgetWithIcon(TextButton, Icons.call_outlined);
        await tester.ensureVisible(voice);
        await tester.tap(voice);
        await tester.pumpAndSettle();
        expect(accepted, CallInitialMedia.audio);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('操作期间禁止重复接听，失败可重试', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await mount(
      tester,
      size: const Size(600, 344),
      accept: (_) {
        calls++;
        return pending.future;
      },
    );
    final accept = find.byKey(const ValueKey('incoming-call-accept'));
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pump();
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    expect(calls, 1);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('api_request_failed'.tr()), findsOneWidget);
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('群呼不遮挡页面且保留加入入口', (tester) async {
    await mount(
      tester,
      invite: const CallInvitationState(
        inviteId: 'group-invite',
        roomId: 'room',
        title: 'Design team',
        callerName: 'Alex',
        createdAt: 0,
        phase: CallInvitationPhase.incoming,
        isGroup: true,
      ),
    );
    expect(find.byKey(const ValueKey('incoming-call-backdrop')), findsNothing);
    expect(find.byKey(const ValueKey('incoming-call-accept')), findsOneWidget);
    final rect = tester.getRect(
      find.byKey(const ValueKey('incoming-call-card')),
    );
    expect(rect.center.dx, closeTo(640, 1));
    expect(rect.center.dy, closeTo((800 + kToolbarHeight) / 2, 1));
  });
}
