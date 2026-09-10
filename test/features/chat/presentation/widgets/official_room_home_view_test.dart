import 'package:anoxia/features/chat/presentation/widgets/official_room_home_view.dart';
import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 打桩更新检查器：直接返回固定状态，不启动定时检查。
class _StubUpdateChecker extends AppUpdateCheckerNotifier {
  _StubUpdateChecker(this.value);

  final AppUpdateInfo? value;

  @override
  AppUpdateInfo? build() => value;
}

/// 打桩 WS 控制器：直接返回连接状态，不建立真实连接。
class _StubWsController extends WsController {
  @override
  WsState build() => WsState(status: WsStatus.connected);
}

Widget _buildApp({AppUpdateInfo? updateStub, List<dynamic> extra = const []}) {
  return ProviderScope(
    overrides: [
      // 隔离平台调用与重依赖：版本 / 网络 / WS 全部打桩
      appVersionProvider.overrideWith((ref) async => '1.0.0'),
      appUpdateCheckerProvider.overrideWith(
        () => _StubUpdateChecker(updateStub),
      ),
      networkStatusProvider.overrideWith(
        (ref) => const Stream<List<ConnectivityResult>>.empty(),
      ),
      wsControllerProvider.overrideWith(() => _StubWsController()),
      ...extra,
    ],
    child: const MaterialApp(
      home: Scaffold(body: OfficialRoomHomeView()),
    ),
  );
}

void main() {
  testWidgets('桌面宽度：隐藏扫一扫、展示系统公告，各区块完整渲染', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.image(AssetImage(Assets.images.appIconPng.path)), findsOneWidget);
    // 桌面端不展示移动端专属的扫一扫
    expect(find.text('official_room_action_scan'), findsNothing);
    // 桌面端展示系统公告入口
    expect(find.text('official_room_action_announcement'), findsOneWidget);
    // 各区块标题至少渲染一次
    expect(find.text('official_room_action_title'), findsAtLeast(1));
    expect(find.text('official_room_feat_title'), findsAtLeast(1));
    expect(find.text('official_room_feat_ai'), findsOneWidget);
    expect(find.text('official_room_onboarding_title'), findsAtLeast(1));
    expect(find.text('official_room_faq_title'), findsAtLeast(1));
    expect(find.text('official_room_faq_q1'), findsOneWidget);
    expect(find.text('official_room_tips_title'), findsAtLeast(1));
    expect(find.text('official_room_tip_pin'), findsOneWidget);
    expect(find.text('official_room_nav_title'), findsAtLeast(1));
    expect(find.text('official_room_nav_settings'), findsOneWidget);
    // 页脚（无本地化代理时 .tr() 回退为 key，拼接版本）
    expect(find.text('official_room_footer_version 1.0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('移动端宽度：展示扫一扫、不展示系统公告', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    if (kIsWeb) {
      // Web 测试 runner 下 isRealMobile 恒为 false（kIsWeb=true），
      // 「扫一扫」在 Web 一律隐藏，只能验证隐藏态。
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('official_room_action_scan'), findsNothing);
      expect(find.text('official_room_action_announcement'), findsNothing);
      expect(tester.takeException(), isNull);
      return;
    }

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('official_room_action_scan'), findsOneWidget);
    expect(find.text('official_room_action_announcement'), findsNothing);
    expect(find.text('official_room_action_add_friend'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('有可用更新时展示更新横幅，可暂不提醒', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const updateInfo = AppUpdateInfo(
      hasUpdate: true,
      latestVersion: '2.0.0',
      currentVersion: '1.0.0',
      downloadUrl: '',
      releaseNotes: 'new features',
      forceUpdate: false,
      minSupportVersion: '',
    );

    await tester.pumpWidget(
      _buildApp(updateStub: updateInfo),
    );
    await tester.pumpAndSettle();

    expect(find.text('official_room_update_check'), findsOneWidget);
    expect(find.text('official_room_update_badge'), findsOneWidget);

    // 点「暂不提醒」后横幅消失
    await tester.tap(find.byTooltip('official_room_update_dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('official_room_update_check'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
