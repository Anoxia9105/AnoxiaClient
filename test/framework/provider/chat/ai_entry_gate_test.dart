// P0-3 AI 入口门控 widget 测试。
//
// spec 要求「AI 不可用时不显示入口」：
// - 未读总结引导条：`chatAvailable` 无法用 / 判断不可读低于阈值两路均隐藏；
//   可用 + 未读 ≥ 20 展示，点击进入总结弹层。
// - 消息长按菜单：flags off / on 都不出现「翻译」（独立翻译面板已下线，
//   翻译统一走问 AI 气泡内的提示词）；flags on 出现「问 AI」。
//
// 注入同 message_read_indicator_test 模板（easy_localization 三要素 +
// UncontrolledProviderScope）；flags 用手工 AsyncNotifier 的子类覆写。
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/ai_unread_summary.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    if (!file.existsSync()) return Future<Map<String, dynamic>?>.value();
    return Future<Map<String, dynamic>?>.value(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }
}

class _StaticFlags extends AiFeatureFlagsNotifier {
  final AiFeatureFlags flags;
  _StaticFlags(this.flags);

  @override
  Future<AiFeatureFlags> build() async => flags;
}

ChatMessage textMessage() => ChatMessage(
  messageId: 'm1',
  clientMsgId: 'c1',
  roomId: 'r1',
  senderId: 2,
  seq: 10,
  messageType: MessageType.text,
  content: 'hello ai',
  deliveryStatus: DeliveryStatus.sent,
);

Future<void> _pumpHarness(
  WidgetTester tester, {
  required AiFeatureFlags flags,
  required Widget child,
  ChatRoomVO? currentRoom,
  LocalDataSource? dataSource,
}) async {
  // 类型不点名（flutter_riverpod 不导出 Override）：由列表字面量推断
  final overrides = [
    aiFeatureFlagsProvider.overrideWith(() => _StaticFlags(flags)),
    if (currentRoom != null)
      currentRoomProvider('r1').overrideWith((ref) => currentRoom),
    if (dataSource != null)
      localDataSourceProvider.overrideWith((ref) => dataSource),
  ];
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  // 预热 flags：菜单/横幅判定依赖 `value`，AsyncNotifier 未就绪时
  // `?? true` 会误判为可用——先等 flags 完成加载再渲染。
  await container.read(aiFeatureFlagsProvider.future);

  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: 'assets/i18n',
        assetLoader: const _DiskAssetLoader(),
        fallbackLocale: const Locale('zh'),
        startLocale: const Locale('zh'),
        useFallbackTranslations: true,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChatRoomVO _room({required int unreadCount, int lastReadSeq = 0}) =>
    ChatRoomVO(
      roomId: 'r1',
      roomType: 0,
      peerId: 2,
      unreadCount: unreadCount,
      lastReadSeq: lastReadSeq,
    );

void main() {
  testWidgets('flags 不可用 → 引导条不显示', (tester) async {
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: false,
      ),
      currentRoom: _room(unreadCount: 40),
      child: const Scaffold(
        body: Stack(
          children: [AiUnreadSummaryBanner(roomId: 'r1')],
        ),
      ),
    );
    expect(find.text('AI 总结未读'), findsNothing);
  });

  testWidgets('flags 可用但未读低于阈值 → 引导条不显示', (tester) async {
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      ),
      currentRoom: _room(unreadCount: 10),
      child: const Scaffold(
        body: Stack(
          children: [AiUnreadSummaryBanner(roomId: 'r1')],
        ),
      ),
    );
    expect(find.text('AI 总结未读'), findsNothing);
  });

  testWidgets('flags 可用 + 未读 ≥ 20 → 引导条显示，点击打开总结弹层', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      ),
      currentRoom: _room(unreadCount: 40),
      dataSource: LocalDataSource(db),
      child: const Scaffold(
        body: SafeArea(
          child: AiUnreadSummaryBanner(roomId: 'r1'),
        ),
      ),
    );
    expect(find.text('AI 总结未读'), findsOneWidget);

    await tester.tap(find.text('AI 总结未读'));
    await tester.pumpAndSettle();
    expect(find.text('未读总结'), findsOneWidget);
  });

  testWidgets('总结弹层空结果文案（媒体-only 未读）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final source = LocalDataSource(db);
    // 一条空文本消息（image caption 空）→ 无可总结文本
    await source.upsertMessage(
      ChatMessage(
        messageId: 'pic1',
        clientMsgId: 'c-pic1',
        roomId: 'r1',
        senderId: 2,
        seq: 6,
        messageType: MessageType.image,
        content: '',
        deliveryStatus: DeliveryStatus.sent,
      ),
    );
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      ),
      currentRoom: _room(unreadCount: 25, lastReadSeq: 5),
      dataSource: source,
      child: const AiUnreadSummarySheet(roomId: 'r1'),
    );
    expect(find.text('没有可总结的未读内容'), findsOneWidget);
  });

  testWidgets('消息菜单翻译项已移除：flags off 只是不出现任何 AI 入口', (tester) async {
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: false,
      ),
      child: Scaffold(
        body: Center(
          child: ChatMessageContextMenu(
            message: textMessage(),
            child: const Text('气泡文本'),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('气泡文本'));
    await tester.pumpAndSettle();
    expect(find.text('翻译'), findsNothing);
    expect(find.text('问 AI'), findsNothing);
  });

  testWidgets('消息菜单翻译项已移除；flags 可用只出问 AI', (tester) async {
    await _pumpHarness(
      tester,
      flags: const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      ),
      child: Scaffold(
        body: Center(
          child: ChatMessageContextMenu(
            message: textMessage(),
            child: const Text('气泡文本'),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('气泡文本'));
    await tester.pumpAndSettle();
    // 独立翻译面板已下线：翻译统一从「问 AI」气泡内的提示词进入。
    expect(find.text('翻译'), findsNothing);
    expect(find.text('问 AI'), findsOneWidget,
        reason: '同一个 chatAvailable 门控，flags on 时问 AI 应出现');
  });
}
