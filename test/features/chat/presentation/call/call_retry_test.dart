import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends Fake implements CallRepository {
  @override
  Future<String> fetchCallToken(String roomId) async => 'same-token';
}

class _FailedRoom extends RoomController {
  _FailedRoom(this.release, this.onBuild);
  final Completer<void> release;
  final VoidCallback onBuild;

  @override
  Future<RoomState> build(String token) async {
    onBuild();
    throw StateError('offline');
  }

  @override
  Future<void> leave() => release.future;
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final cancel in [false, true]) {
    testWidgets(cancel ? '退出页面后不再交付重试令牌' : '相同令牌也在旧媒体释放后重建并交付给窗口', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      final release = Completer<void>();
      var builds = 0;
      var deliveries = 0;
      var showCall = true;
      late StateSetter update;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          callRepositoryProvider.overrideWithValue(_Repository()),
          roomControllerProvider(
            'same-token',
          ).overrideWith(() => _FailedRoom(release, () => builds++)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
                home: Scaffold(
                  body: StatefulBuilder(
                    builder: (context, setState) {
                      update = setState;
                      return NotificationListener<CallRetryTokenNotification>(
                        onNotification: (notification) {
                          deliveries++;
                          return true;
                        },
                        child: showCall
                            ? const CallRoomPage(
                                token: 'same-token',
                                roomId: 'room',
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(builds, 1);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(deliveries, 0);
      expect(builds, 1);
      if (cancel) {
        update(() => showCall = false);
        await tester.pump();
      }
      release.complete();
      await tester.pumpAndSettle();
      expect(deliveries, cancel ? 0 : 1);
      expect(builds, cancel ? 1 : 2);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }
}
