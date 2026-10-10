import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_list.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

class _Rooms extends RoomListService {
  int refreshes = 0;
  final pending = Completer<void>();
  @override
  List<ChatRoomVO> build() => [];
  @override
  Future<void> refresh({bool silent = false}) {
    refreshes++;
    return pending.future;
  }
}

class _Contacts extends ContactListService {
  int refreshes = 0;
  final pending = Completer<void>();
  @override
  Map<int, ChatContactVO> build() => {};
  @override
  Future<void> refresh({bool quiet = false}) {
    refreshes++;
    return pending.future;
  }
}

class _RoomFailure extends RoomListRefreshFailed {
  @override
  bool build() => false;
}

class _ContactFailure extends ContactRefreshFailed {
  @override
  bool build() => false;
}

Future<void> _mount(
  WidgetTester tester, {
  required Widget page,
  required _Rooms rooms,
  required _Contacts contacts,
  bool desktop = false,
  bool contactError = false,
  bool emptyContacts = false,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = desktop
      ? const Size(1440, 900)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh')],
      path: 'assets/i18n',
      startLocale: const Locale('zh'),
      assetLoader: const _DiskLoader(),
      child: ProviderScope(
        overrides: [
          roomListServiceProvider.overrideWith(() => rooms),
          roomListRefreshFailedProvider.overrideWith(_RoomFailure.new),
          filteredSortedRoomListAsyncProvider.overrideWith(
            (ref) => const AsyncData([]),
          ),
          contactListServiceProvider.overrideWith(() => contacts),
          contactRefreshFailedProvider.overrideWith(_ContactFailure.new),
          pendingRequestCountProvider.overrideWith((ref) async => 0),
          sortedContactGroupsProvider.overrideWith((ref) async {
            if (contactError) throw StateError('offline');
            return emptyContacts
                ? {}
                : {
                    'A': [ChatContactVO(contactId: 2, nickName: 'Alice')],
                  };
          }),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: AppTheme.getThemeByModeAndAccent(
              brightness: brightness,
              accentIndex: 0,
            ),
            home: page,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('聊天刷新圆盘使用不透明底色：$brightness', (tester) async {
      final rooms = _Rooms();
      await _mount(
        tester,
        page: const ChatRoomList(),
        rooms: rooms,
        contacts: _Contacts(),
        brightness: brightness,
      );
      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(indicator.backgroundColor?.a, 1);
      await tester.dragFrom(
        tester.getTopLeft(find.byType(CustomScrollView)) + const Offset(60, 40),
        const Offset(0, 400),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(rooms.refreshes, 1);
      rooms.pending.complete();
      await tester.pumpAndSettle();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  for (final mode in ['short', 'empty', 'error']) {
    testWidgets('手机联系人 $mode 状态可以下拉刷新', (tester) async {
      final contacts = _Contacts();
      await _mount(
        tester,
        page: const ContactList(),
        rooms: _Rooms(),
        contacts: contacts,
        contactError: mode == 'error',
        emptyContacts: mode == 'empty',
      );
      final scrollable = find.byType(Scrollable).first;
      expect(find.byTooltip('刷新列表'), findsNothing);
      expect(scrollable, findsOneWidget);
      await tester.dragFrom(
        tester.getTopLeft(scrollable) + const Offset(60, 40),
        const Offset(0, 400),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(contacts.refreshes, 1);
      contacts.pending.complete();
      await tester.pumpAndSettle();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  for (final chat in [true, false]) {
    testWidgets('桌面${chat ? '聊天' : '联系人'}刷新按钮等待完成且防止重复请求', (tester) async {
      final rooms = _Rooms();
      final contacts = _Contacts();
      await _mount(
        tester,
        page: chat ? const ChatRoomList() : const ContactList(),
        rooms: rooms,
        contacts: contacts,
        desktop: true,
        contactError: !chat,
      );
      final refresh = find.byTooltip('刷新列表');
      expect(refresh, findsOneWidget);
      final button = find.ancestor(
        of: refresh,
        matching: find.byType(IconButton),
      );
      await tester.tap(refresh);
      await tester.pump();
      expect(chat ? rooms.refreshes : contacts.refreshes, 1);
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      await tester.tap(
        find.text(chat ? 'chat_rooms_action'.tr() : 'call_window_retry'.tr()),
      );
      await tester.pump();
      expect(chat ? rooms.refreshes : contacts.refreshes, 1);
      expect(
        find.descendant(
          of: refresh,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      (chat ? rooms.pending : contacts.pending).complete();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }
}
