// P0-2 单聊已读回执：气泡状态指示器 widget 测试。
//
// 按 AGENTS.md 的 easy_localization 测试要求：
// - mock SharedPreferences + `EasyLocalizationController.ensureInitialized`；
// - 语言包用自定义 AssetLoader **同步**读磁盘并返回 `Future.value`
//   （widget 测试跑在 fake async 里，真实异步 I/O 不会被 pump 推进）；
// - 内层 MaterialApp 必须挂上 `context.localizationDelegates`，
//   否则 delegate.load() 不会执行、`.tr()` 只回吐 key；
// - 显式传 `startLocale`（设备 locale 会解析到不存在的语言包）。
//
// Provider 侧注入：
// - `currentRoomProvider('r1')` 覆写为最小 ChatRoomVO（单聊/群聊可切换）；
// - `roomMemberServiceProvider` 是 keepAlive Notifier，直接手工置 state
//   模拟「进入会话时成员接口快照已就位」。
//   （不覆写 authControllerProvider——本链路不读它。）
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_status_indicators.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试环境直接读磁盘语言包（同步读 + Future.value，见文件头说明）。
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

ChatMessage _sentMessage({int? seq}) => ChatMessage(
  messageId: 'm1',
  clientMsgId: 'c1',
  roomId: 'r1',
  senderId: 1,
  seq: seq,
  timestamp: 1700000000000,
  messageType: MessageType.text,
  content: 'hello',
  deliveryStatus: DeliveryStatus.sent,
);

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required ChatRoomVO room,
  ChatRoomMemberVO? peerMember,
  required ChatMessage message,
  // 进度圈是无限动画，用例遇到它时必须关掉 pumpAndSettle
  bool settle = true,
}) async {
  // 模拟「进入会话时成员接口快照已就位」由 roomEntryTask syncMembers 拉取。
  final container = ProviderContainer(
    overrides: [currentRoomProvider('r1').overrideWith((ref) => room)],
  );
  addTearDown(container.dispose);
  if (peerMember != null) {
    container.read(roomMemberServiceProvider.notifier).state = {
      'r1': {2: peerMember},
    };
  }

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
            home: Scaffold(
              body: Center(
                child: MessageStatusIndicators(
                  message: message,
                  isMentionedMe: false,
                  isCurrentUser: true,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // 定长两帧：跳过进度圈的持续动画，仅推进布局与本地化装配
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('单聊 + 对端水位覆盖 seq → 显示「已读」', (tester) async {
    await _pumpIndicator(
      tester,
      room: ChatRoomVO(roomId: 'r1', roomType: 0, peerId: 2),
      peerMember: ChatRoomMemberVO(userId: 2, lastReadSeq: 20),
      message: _sentMessage(seq: 10),
    );
    expect(find.text('已读'), findsOneWidget);
    expect(find.text('已送达'), findsNothing);
  });

  testWidgets('单聊 + 对端水位低于 seq → 显示「已送达」', (tester) async {
    await _pumpIndicator(
      tester,
      room: ChatRoomVO(roomId: 'r1', roomType: 0, peerId: 2),
      peerMember: ChatRoomMemberVO(userId: 4, lastReadSeq: 5),
      message: _sentMessage(seq: 10),
    );
    expect(find.text('已送达'), findsOneWidget);
    expect(find.text('已读'), findsNothing);
  });

  testWidgets('单聊 + 成员快照缺失（水位未知）→ 显示「已送达」', (tester) async {
    await _pumpIndicator(
      tester,
      room: ChatRoomVO(roomId: 'r1', roomType: 0, peerId: 2),
      // peerMember 故意不注入：模拟成员接口不可用/未同步
      message: _sentMessage(seq: 10),
    );
    expect(find.text('已送达'), findsOneWidget);
    expect(find.text('已读'), findsNothing);
  });

  testWidgets('群聊不显示回执标签', (tester) async {
    await _pumpIndicator(
      tester,
      room: ChatRoomVO(roomId: 'r1', roomType: 1),
      peerMember: ChatRoomMemberVO(userId: 2, lastReadSeq: 99),
      message: _sentMessage(seq: 10),
    );
    expect(find.text('已读'), findsNothing);
    expect(find.text('已送达'), findsNothing);
  });

  testWidgets('发送中的消息仍是进度圈，不叠加回执', (tester) async {
    await _pumpIndicator(
      tester,
      room: ChatRoomVO(roomId: 'r1', roomType: 0, peerId: 2),
      peerMember: ChatRoomMemberVO(userId: 2, lastReadSeq: 20),
      message: ChatMessage(
        messageId: 'm1',
        clientMsgId: 'c1',
        roomId: 'r1',
        senderId: 1,
        timestamp: 1700000000000,
        messageType: MessageType.text,
        content: 'hello',
        deliveryStatus: DeliveryStatus.sending,
      ),
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('已读'), findsNothing);
    expect(find.text('已送达'), findsNothing);
  });
}
