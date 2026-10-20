import 'dart:convert';
import 'dart:io';

import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/features/chat/presentation/pages/call_history_page.dart';
import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:anoxia/framework/domain/room_call_status.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试环境直接读磁盘语言包。
///
/// `flutter test` 下 rootBundle 取不到 assets/i18n，若沿用默认加载器，
/// `.tr()` 只会返回 key 本身，断言就失去意义。用同步读 + `Future.value`：
/// widget 测试跑在 fake async 里，真正的异步 I/O 不会被推进。
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

/// 页面级假仓库：固定返回一页数据（null 则固定抛错）。
class _FixedCallRepository implements CallRepository {
  _FixedCallRepository(this.page);

  final CallHistoryPageData? page;
  int historyCalls = 0;

  @override
  Future<CallHistoryPageData> fetchCallHistory({
    required int pageNum,
    required int pageSize,
    required String orderBy,
    String? roomId,
  }) {
    historyCalls++;
    expect(roomId, 'room-a');
    final data = page;
    if (data == null) {
      return Future.error(const FormatException('invalid response'));
    }
    return Future.value(data);
  }

  @override
  Future<RoomCallStatus> fetchCallStatus(String roomId) =>
      throw UnimplementedError();

  @override
  Future<String> fetchCallToken(String roomId) => throw UnimplementedError();

  @override
  Future<bool> removeParticipant(String roomId, String identity) =>
      throw UnimplementedError();
}

CallLogEntry completedOutgoing() => const CallLogEntry(
      messageId: 'm1',
      roomId: 'room-a',
      roomType: 0,
      peerName: '张三',
      outgoing: true,
      startAt: 1600000000000,
      endAt: 1600000000080,
      durationSec: 80,
      durationText: '01:20',
      status: CallLogStatus.completed,
    );

CallLogEntry ongoingIncomingGroup() => const CallLogEntry(
      messageId: 'm2',
      roomId: 'room-g',
      roomType: 1,
      roomName: '项目群',
      outgoing: false,
      startAt: 1600000000000,
      status: CallLogStatus.ongoing,
    );

/// 宿主页：用「presentAdaptivePage 打开通话记录」的真实入口断言——
/// 宽屏（≥700 逻辑宽）走桌面模态弹窗，窄屏走整页路由，
/// 点击条目 pop 后应回到宿主页。
class _HostScreen extends StatelessWidget {
  const _HostScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => presentAdaptivePage(
            context,
            builder: (_) => const CallHistoryPage(roomId: 'room-a'),
          ),
          child: const Text('打开通话记录'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHost(
  WidgetTester tester, {
  required Locale locale,
  required CallRepository repository,
  Size physicalSize = const Size(800, 600),
  double devicePixelRatio = 1.0,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  final container = ProviderContainer(
    overrides: [callRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      path: 'assets/i18n',
      assetLoader: const _DiskAssetLoader(),
      fallbackLocale: locale,
      startLocale: locale,
      useFallbackTranslations: true,
      // 必须把 EasyLocalization 的 delegates 交给内层 MaterialApp，
      // 否则 assemble 阶段不会调用 delegate.load()，`.tr()` 只会返回 key。
      // ProviderScope 必须包在 MaterialApp 外层：presentAdaptivePage
      // 把弹窗/整页路由推入根 Navigator（Overlay 在 MaterialApp 之下），
      // 否则新路由里的 Consumer 读不到容器（No ProviderScope found）。
      child: UncontrolledProviderScope(
        container: container,
        // 必须把 EasyLocalization 的 delegates 交给内层 MaterialApp，
        // 否则 assemble 阶段不会调用 delegate.load()，`.tr()` 只会返回 key。
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const _HostScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  // 经真实入口打开：宽屏为模态弹窗，窄屏为 Material 路由。
  // 项目自定义了页面过渡（离场/入场时长大于常规值），统一 pumpAndSettle。
  await tester.tap(find.text('打开通话记录'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('桌面弹窗渲染条目（zh）：标题/呼出/时长/进行中 + 条目可关闭', (tester) async {
    await _pumpHost(
      tester,
      locale: const Locale('zh'),
      repository: _FixedCallRepository(
        CallHistoryPageData(
          entries: [completedOutgoing(), ongoingIncomingGroup()],
          total: 2,
        ),
      ),
    );

    expect(find.byType(CallHistoryPage), findsOneWidget);
    expect(find.text('通话记录'), findsNWidgets(1));
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('项目群'), findsOneWidget);
    expect(find.text('呼出'), findsOneWidget);
    expect(find.text('呼入'), findsOneWidget);
    expect(find.text('01:20'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('没有更多了'), findsOneWidget);

    // 点击条目 → 关闭弹窗回到宿主页。
    // 项目自定义了页面过渡：离场动画超过常规 300ms，用 pumpAndSettle 等待。
    await tester.tap(find.text('张三'));
    await tester.pumpAndSettle();
    expect(find.byType(CallHistoryPage), findsNothing);
  });

  testWidgets('空列表展示空态文案（zh）', (tester) async {
    await _pumpHost(
      tester,
      locale: const Locale('zh'),
      repository: _FixedCallRepository(CallHistoryPageData.empty),
    );

    expect(find.text('还没有通话记录'), findsOneWidget);
  });

  testWidgets('首屏失败展示重试入口（zh）', (tester) async {
    final repository = _FixedCallRepository(null);
    await _pumpHost(
      tester,
      locale: const Locale('zh'),
      repository: repository,
    );

    expect(find.text('通话记录加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    // 点击重试后仓库再次收到请求
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(repository.historyCalls, 2);
  });

  testWidgets('en 文案渲染', (tester) async {
    await _pumpHost(
      tester,
      locale: const Locale('en'),
      repository: _FixedCallRepository(
        CallHistoryPageData(
          entries: [completedOutgoing(), ongoingIncomingGroup()],
          total: 2,
        ),
      ),
    );

    expect(find.text('Call history'), findsNWidgets(1));
    expect(find.text('Outgoing'), findsOneWidget);
    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('ja 文案渲染', (tester) async {
    await _pumpHost(
      tester,
      locale: const Locale('ja'),
      repository: _FixedCallRepository(
        CallHistoryPageData(
          entries: [completedOutgoing(), ongoingIncomingGroup()],
          total: 2,
        ),
      ),
    );

    expect(find.text('通話履歴'), findsNWidgets(1));
    expect(find.text('発信'), findsOneWidget);
    expect(find.text('着信'), findsOneWidget);
    expect(find.text('通話中'), findsOneWidget);
  });

  testWidgets('移动端整页路由：AppBar 标题 + 条目 pop 回宿主页', (tester) async {
    await _pumpHost(
      tester,
      locale: const Locale('zh'),
      repository: _FixedCallRepository(
        CallHistoryPageData(entries: [completedOutgoing()], total: 1),
      ),
      physicalSize: const Size(400, 800),
    );

    expect(find.byType(CallHistoryPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.title, isA<Text>());
    expect((appBar.title! as Text).data, '通话记录');
    // 非弹窗整页路由：条目点击关闭本页回到宿主页
    await tester.tap(find.text('张三'));
    await tester.pumpAndSettle();
    expect(find.byType(CallHistoryPage), findsNothing);
  });
}
