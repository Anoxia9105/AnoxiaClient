import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/call/component/call_media_settings_dialog.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/domain/call_media_preferences.dart';
import 'package:anoxia/common/widgets/app_select_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:shared_preferences/shared_preferences.dart';

class _Room extends Fake implements lk.Room {}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['zh', 'en', 'ja']) {
    testWidgets('设置在 320px 下可滚动并保存：$language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      CallMediaPreferences? saved;
      final roomState = RoomState(
        room: _Room(),
        token: 'test',
        connectionState: lk.ConnectionState.connected,
        micEnabled: true,
        cameraEnabled: false,
        screenSharing: false,
        speakerOn: false,
        audioInputs: const [],
        audioOutputs: const [],
        videoInputs: const [],
        remoteParticipants: const [],
      );
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
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showCallMediaSettings(context, roomState, (
                      value,
                    ) async {
                      saved = value;
                    }),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('call-camera-quality')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsWidgets);
      final quality = tester.widget<AppSelectField<CameraQuality>>(
        find.byKey(const ValueKey('call-camera-quality')),
      );
      final highLabel = quality.options
          .firstWhere((o) => o.value == CameraQuality.high)
          .label;
      await tester.tap(find.widgetWithText(MenuItemButton, highLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(saved?.cameraQuality, CameraQuality.high);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
