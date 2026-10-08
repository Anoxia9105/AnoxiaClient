import 'dart:async';

import 'package:anoxia/common/widgets/app/mobile_bottom_bar.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_item.dart';
import 'package:anoxia/features/me/presentation/pages/menu_page.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定量推进帧（不用 pumpAndSettle：MenuPage 的 loading 骨架屏是无限 shimmer）。
Future<void> _pumpFrames(WidgetTester tester, [int frames = 30]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
/// 复现「web --wasm 下切换到 SP 模式报 Maximum call stack size exceeded」：
/// 窄屏挂载 ZoomDrawer + MenuPage + MobileBottomBar + ChatRoomList，
/// 再切回宽屏、再切回窄屏，全程 pumpAndSettle 不得抛异常/卡死。
Future<void> _pumpSpTree(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      useFallbackTranslations: true,
      child: ProviderScope(
        overrides: [
          // networkStatus 内含 checkConnectivity().timeout(3s)，
          // 本文件用定量 pump（非 pumpAndSettle），3s 定时器到不了触发点，
          // teardown 会报 pending timer，用静态流代替。
          networkStatusProvider.overrideWith(
            (ref) => Stream.value(const [ConnectivityResult.wifi]),
          ),
          totalUnreadCountProvider.overrideWith((ref) => 0),
          pendingRequestCountProvider.overrideWith((ref) => 0),
          filteredSortedRoomListAsyncProvider.overrideWithValue(
            const AsyncData([]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.getThemeByModeAndAccent(
            brightness: Brightness.light,
            accentIndex: 0,
          ),
          home: const _SpSwitchHarness(),
        ),
      ),
    ),
  );
  await _pumpFrames(tester);
}

/// 用与 MainLayoutPage 相同的断点在 ZoomDrawer(SP) 与桌面主体(PC) 间切换。
class _SpSwitchHarness extends StatelessWidget {
  const _SpSwitchHarness();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 600) {
      return ZoomDrawer(
        menuBackgroundColor: Theme.of(context).colorScheme.primary,
        menuScreen: const MenuPage(),
        mainScreen: const Scaffold(
          body: ChatRoomList(),
          bottomNavigationBar: MobileBottomBar(),
        ),
        borderRadius: 24.0,
        showShadow: false,
        angle: 0.0,
        slideWidth: 260,
        menuScreenWidth: 260,
      );
    }
    return const Scaffold(
      body: Center(child: Text('PC')),
      bottomNavigationBar: null,
    );
  }
}

void main() {
  group('SP/PC 布局切换不崩溃', () {
    testWidgets('窄屏挂载 SP 树', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSpTree(tester);
      expect(find.byType(ZoomDrawer), findsOneWidget);
      expect(find.byType(MobileBottomBar), findsOneWidget);
      expect(find.byType(MenuPage), findsOneWidget);
    });

    testWidgets('PC -> SP -> PC 来回切换', (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSpTree(tester);
      expect(find.text('PC'), findsOneWidget);

      // 切到 SP。
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      await _pumpFrames(tester);
      expect(find.byType(ZoomDrawer), findsOneWidget);
      expect(find.byType(MobileBottomBar), findsOneWidget);

      // 切回 PC。
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      await _pumpFrames(tester);
      expect(find.text('PC'), findsOneWidget);

      // 再切回 SP。
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      await _pumpFrames(tester);
      expect(find.byType(ZoomDrawer), findsOneWidget);
    });

    testWidgets('SP 下真实房间数据列表渲染与切换', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues(const {});
      await EasyLocalization.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async => null,
          );
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('zh'),
          startLocale: const Locale('zh'),
          useFallbackTranslations: true,
          child: ProviderScope(
            overrides: [
              networkStatusProvider.overrideWith(
                (ref) => Stream.value(const [ConnectivityResult.wifi]),
              ),
              totalUnreadCountProvider.overrideWith((ref) => 5),
              pendingRequestCountProvider.overrideWith((ref) => 0),
              roomListServiceProvider.overrideWith(
                () => _FakeRoomListService(_kTestRooms),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.getThemeByModeAndAccent(
                brightness: Brightness.light,
                accentIndex: 0,
              ),
              home: const _SpSwitchHarness(),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(find.byType(ZoomDrawer), findsOneWidget);
      // 三个房间行都渲染出来（含头像/预览/未读；官方虚拟房间可能额外注入一行）。
      expect(find.byType(RoomListItem), findsAtLeastNWidgets(3));

      // 切到 PC 再切回 SP：房间行重建不得崩溃。
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      await _pumpFrames(tester);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      await _pumpFrames(tester);
      expect(find.byType(RoomListItem), findsAtLeastNWidgets(3));
    });

    testWidgets('SP 登录态抽屉头部头像渲染与切换', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues(const {});
      await EasyLocalization.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async => null,
          );
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('zh'),
          startLocale: const Locale('zh'),
          useFallbackTranslations: true,
          child: ProviderScope(
            overrides: [
              networkStatusProvider.overrideWith(
                (ref) => Stream.value(const [ConnectivityResult.wifi]),
              ),
              totalUnreadCountProvider.overrideWith((ref) => 5),
              pendingRequestCountProvider.overrideWith((ref) => 0),
              roomListServiceProvider.overrideWith(
                () => _FakeRoomListService(_kTestRooms),
              ),
              authControllerProvider.overrideWith(
                () => _FakeAuthController(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.getThemeByModeAndAccent(
                brightness: Brightness.light,
                accentIndex: 0,
              ),
              home: const _SpSwitchHarness(),
            ),
          ),
        ),
      );
      await _pumpFrames(tester, 60);
      expect(find.byType(ZoomDrawer), findsOneWidget);
      expect(find.byType(MenuPage), findsOneWidget);
      // 抽屉头部渲染出登录用户昵称。
      expect(find.text('测试用户'), findsOneWidget);

      // 切 PC 再回 SP。
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      await _pumpFrames(tester);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      await _pumpFrames(tester);
      expect(find.byType(ZoomDrawer), findsOneWidget);
    });
  });
}

List<ChatRoomVO> get _kTestRooms => [
  ChatRoomVO(
    roomId: 'room-single',
    roomName: '测试单聊',
    roomAvatar: 'https://example.com/avatar1.png',
    roomType: 0,
    roomStatus: 0,
    unreadCount: 3,
    lastMessage: ChatMessage(
      messageId: 'm1',
      roomId: 'room-single',
      messageType: MessageType.text,
      content: '你好，在吗？',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ),
  ChatRoomVO(
    roomId: 'room-group',
    roomName: '测试群聊',
    roomAvatar: 'https://example.com/avatar2.png',
    roomType: 1,
    roomStatus: 0,
    unreadCount: 0,
    lastMessage: ChatMessage(
      messageId: 'm2',
      roomId: 'room-group',
      messageType: MessageType.richText,
      content: '富文本消息',
      payload: const MessagePayload(
        content: '富文本消息',
        quillDelta:
            '[{"insert":"富文本消息\\n"}]',
      ),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ),
  ChatRoomVO(
    roomId: 'room-image',
    roomName: '图片房间',
    roomType: 1,
    roomStatus: 0,
    unreadCount: 12,
    lastMessage: ChatMessage(
      messageId: 'm3',
      roomId: 'room-image',
      messageType: MessageType.image,
      content: '[image]',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ),
];

class _FakeRoomListService extends RoomListService {
  _FakeRoomListService(this.rooms);

  final List<ChatRoomVO> rooms;

  @override
  FutureOr<List<ChatRoomVO>> build() => rooms;
}

class _FakeAuthController extends AuthController {
  @override
  Future<UserInfo?> build() async => UserInfo(
    userId: 1,
    userName: 'testuser',
    nickName: '测试用户',
    email: 'test@example.com',
    phoneNumber: '13800000000',
    sex: '0',
    avatar: 'https://example.com/my-avatar.png',
  );
}
