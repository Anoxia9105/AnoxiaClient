// P0-4 媒体时间线页面 widget 测试。
//
// 注入方式参照 message_read_indicator_test.dart（easy_localization 三要素 +
// UncontrolledProviderScope）；数据库用内存 drift + 覆写
// `localDataSourceProvider` 直接喂种子消息，不走网络。
import 'dart:convert';
import 'dart:io';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:anoxia/features/chat/presentation/pages/media_timeline_page.dart';
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

ChatMessage imageMessage(String id, int seq) => ChatMessage(
  messageId: id,
  clientMsgId: 'client-$id',
  roomId: 'r1',
  senderId: 1,
  seq: seq,
  timestamp: 1700000000000 + seq * 1000,
  messageType: MessageType.image,
  content: 'pic',
  payload: MessagePayload(
    image: Attachment(url: 'https://cdn.example.com/$id.png', width: 100),
  ),
  deliveryStatus: DeliveryStatus.sent,
);

ChatMessage fileMessage(String id, int seq) => ChatMessage(
  messageId: id,
  clientMsgId: 'client-$id',
  roomId: 'r1',
  senderId: 1,
  seq: seq,
  timestamp: 1700000000000 + seq * 1000,
  messageType: MessageType.file,
  content: 'doc.pdf',
  payload: MessagePayload(
    file: Attachment(
      url: 'https://cdn.example.com/$id.pdf',
      name: 'doc.pdf',
      size: 2048,
    ),
  ),
  deliveryStatus: DeliveryStatus.sent,
);

ChatMessage linkMessage(String id, int seq, String content) => ChatMessage(
  messageId: id,
  clientMsgId: 'client-$id',
  roomId: 'r1',
  senderId: 1,
  seq: seq,
  timestamp: 1700000000000 + seq * 1000,
  messageType: MessageType.text,
  content: content,
  deliveryStatus: DeliveryStatus.sent,
);

Future<void> _pumpTimeline(
  WidgetTester tester, {
  List<ChatMessage> seed = const [],
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final source = LocalDataSource(db);
  for (final m in seed) {
    await source.upsertMessage(m);
  }

  final container = ProviderContainer(
    overrides: [localDataSourceProvider.overrideWith((ref) => source)],
  );
  addTearDown(container.dispose);

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
            home: const MediaTimelinePage(roomId: 'r1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('文件分页按钮位于列表底部，加载最后一页后消失', (tester) async {
    await _pumpTimeline(
      tester,
      seed: [for (var i = 1; i <= 61; i++) fileMessage('file-$i', i)],
    );
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();
    expect(find.text('加载更多'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('加载更多'),
      500,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();
    expect(find.text('加载更多'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('320px 窄屏胶囊页签无溢出且可以切换', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpTimeline(tester);
    await tester.tap(find.text('链接'));
    await tester.pumpAndSettle();
    expect(find.text('暂无内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('链接源消息满页但只有一条链接时不显示加载更多', (tester) async {
    await _pumpTimeline(
      tester,
      seed: [
        for (var i = 1; i <= 61; i++)
          linkMessage(
            'link-$i',
            i,
            i == 61 ? 'https://example.com/last' : '普通文本',
          ),
      ],
    );
    await tester.tap(find.text('链接'));
    await tester.pumpAndSettle();
    expect(find.text('https://example.com/last'), findsOneWidget);
    expect(find.text('加载更多'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('路由 location 含 roomId 查询参数', () {
    const route = MediaTimelineRoute(roomId: 'r1');
    expect(route.location, '/media-timeline?room-id=r1');
  });

  testWidgets('空库时媒体 Tab 显示空态', (tester) async {
    await _pumpTimeline(tester);
    expect(find.text('媒体与链接'), findsOneWidget);
    expect(find.text('媒体'), findsOneWidget);
    expect(find.text('暂无内容'), findsOneWidget);
  });

  testWidgets('媒体 Tab：image 消息展开为九宫格格子', (tester) async {
    await _pumpTimeline(
      tester,
      seed: [imageMessage('i1', 1), imageMessage('i2', 2)],
    );
    // 两个 image 消息 → 格子网格（CachedNetworkImageView 网络图占位）
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.text('暂无内容'), findsNothing);
    expect(
      find.byIcon(Icons.play_circle_fill),
      findsNothing,
      reason: 'image 消息不应出现视频播放标识',
    );
  });

  testWidgets('切到文件 Tab：显示文件名 + 大小', (tester) async {
    await _pumpTimeline(tester, seed: [fileMessage('f1', 10)]);
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();

    expect(find.text('doc.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsOneWidget);
  });

  testWidgets('切到链接 Tab：文本中的 URL 被提取展示', (tester) async {
    await _pumpTimeline(
      tester,
      seed: [
        linkMessage('l1', 10, '看看 https://example.com/a 不错'),
        linkMessage('lr', 11, '没有链接的纯文本'),
        imageMessage('i1', 12),
      ],
    );
    await tester.tap(find.text('链接'));
    await tester.pumpAndSettle();

    // 只展示 URL 本身（首条口径），无链接的文本不出现
    expect(find.text('https://example.com/a'), findsOneWidget);
    expect(find.text('看看 https://example.com/a，不错'), findsNothing);
    expect(find.text('没有链接的纯文本'), findsNothing);
  });

  testWidgets('链接 Tab 空态：普通文本不产生链接', (tester) async {
    await _pumpTimeline(tester, seed: [linkMessage('plain', 1, '早上好')]);
    await tester.tap(find.text('链接'));
    await tester.pumpAndSettle();
    expect(find.text('暂无内容'), findsOneWidget);
  });
}
